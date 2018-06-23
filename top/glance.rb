#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
($LOAD_PATH << File.expand_path("..", __FILE__)).uniq!

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8

require "bundle/bundler/setup"
require "alfred"
require 'plist'
require 'yaml'
require 'mixlib/shellout'
require 'iStats'

class Glance
  SMC_KEYS = {
    'TC0P' => 'cpu_temperature',
    'TG0P' => 'gpu_temperature',
    'F0Ac' => 'fan0_speed',
    'F1Ac' => 'fan1_speed',
  }

  def self.sh(command, opts = {})
    shell = Mixlib::ShellOut.new(command)
    shell.run_command
    shell.error!
    return shell
  end

  def self.with_query(query)
    if query[1].eql? '⟩'
      return query[2..-1]
    else
      return  query
    end
  end

  def initialize(alfred, query)
    @alfred = alfred
    @feedback = @alfred.feedback
    if query[1].eql? '⟩'
      @actor = query[0].downcase
    end
  end


  def collect
    collect_battery
    collect_temperature
    collect_bluetooth
    collect_storage
  end


  def collect_temperature
    return if @actor

    # temp = IStats::Cpu.delegate("all")

#     > IStats.get_info[:cpu_temperature]
# => {:battery_health_stats=>{:battery_health=>"Good", :max_design_cycle_count=>1000, :cycle_count=>"156", :cycle_count_percentage=>15.6, :thresholds=>[450.0, 650.0, 850.0, 950.0], :battery_temp=>31.796875}, :battery_charge_stats=>{:cur_charge=>"3630", :cur_charge_percentage=>64, :original_max_capacity=>6559.0, :current_max_capacity=>5932.0}, :cpu_temperature=>43.5, :cpu_thresholds=>[50, 68, 80, 90], :fan_numbers_and_speeds=>[[1, 0]]}

    cpu_temperature = IStats.get_info[:cpu_temperature]
    icon = {:type => "default", :name => "icon/temperature/GPU.png"}
    @feedback.add_item(
      :subtitle => "CPU: #{cpu_temperature}° C" ,
      :title    => "CPU Temperature"                                     ,
      :uid      => "CPU Temperature"                                     ,
      :icon     => icon)

    # gpu_temperature = 200
    # icon = {:type => "default", :name => "icon/temperature/GPU.png"}
    # @feedback.add_item(
    #   :subtitle => "GPU: #{gpu_temperature}° C" ,
    #   :title    => "GPU Temperature"                                     ,
    #   :uid      => "GPU Temperature"                                     ,
    #   :icon     => icon)

    # [number, speed]
    IStats.get_info[:fan_numbers_and_speeds].each{|info_arr|
      add_fan_speed_item(info_arr)
    }
  end

  def add_fan_speed_item(info_arr)
    fan_number = info_arr[0]
    fan_speed = info_arr[1]
    if fan_speed < 3500
      icon = {:type => "default", :name => "icon/fan/green.png"}
      title = "Fan Speed: Normal"
    elsif fan_speed < 5500
      icon = {:type => "default", :name => "icon/fan/blue.png"}
      title = "Fan Speed: Fast"
    else
      icon = {:type => "default", :name => "icon/fan/red.png"}
      title = "Fan Speed: Driving Crazy!"
    end
    @feedback.add_item(
      :subtitle => "Fan #{fan_number}: #{fan_speed} RPM" ,
      :uid      => "Fan #{fan_number} Speed",
      :title    => title,
      :icon     => icon)

  end

  def collect_storage
    return if @actor

    devices = %x{/bin/df -H}.split("\n")

    devices.each do |device|
      next unless device.start_with? '/dev/'

      items = device.split
      size = items[1]
      used = items[2]
      free = items[3]
      percent = items[4][0...-1].to_i
      mount_point = items[8..-1].join(" ")
      if mount_point.eql? '/'
        name = 'Root'
      else
        name = File.basename(mount_point)
      end
      @feedback.add_file_item(mount_point,
                             :title => "#{name}: #{free} free",
      :subtitle =>"#{percent}%, #{used} used of #{size} total")
    end
  end


  def collect_bluetooth
    return if @actor

    bluetooth_device_keys = ["BNBMouseDevice", "IOAppleBluetoothHIDDriver", "BNBTrackpadDevice"]

    bluetooth_device_keys.each do |key|
      devices = Plist.parse_xml %x{ioreg -l -n #{key} -r -a}
      next if devices.nil? || devices.empty?

      devices.each do |device|
        name = device["Product"]
        serial = device["SerialNumber"]
        percent = device["BatteryPercent"].to_i
        icon = {:type => "default", :name => "icon/bluetooth/#{key}.png"}
        @feedback.add_item(:subtitle => "#{percentage_sign(percent)} #{percent}%",
                          :title => "#{name}",
                          :uid => "#{key}: #{serial}",
        :icon => icon)
      end
    end

  end

  def collect_battery
    if @actor.eql? "battery"
      show_detailed_feedback = true
    else
      if @actor
        return
      else
        show_detailed_feedback = false
      end
    end


    devices = Plist.parse_xml %x{ioreg -l -n AppleSmartBattery -r -a}
    return if devices.nil? || devices.empty?

    devices.each do |device|
      current_capacity = device["CurrentCapacity"]
      max_capacity     = device["MaxCapacity"]
      design_capacity  = device['DesignCapacity']
      temperature      = device['Temperature'].to_f / 100
      is_charging      = device['IsCharging']
      serial           = device['BatterySerialNumber']
      cycle_count      = device['CycleCount']
      fully_charged    = device['FullyCharged']
      is_external      = device['ExternalConnected']
      time_to_full     = device['AvgTimeToFull']
      time_to_empty    = device['AvgTimeToEmpty']
      manufacture_date = device['ManufactureDate']


      day = manufacture_date & 31
      month = (manufacture_date >> 5 ) & 15
      year = 1980 + (manufacture_date >> 9)

      manufacture_date = Date.new(year, month, day)
      # month as unit
      age = (Date.today - manufacture_date).to_f / 30

      health  = max_capacity * 100 / design_capacity
      percent = current_capacity * 100 / max_capacity


      if percent > 80
        icon_name = 'full'
      elsif percent > 50
        icon_name = 'medium'
      elsif percent > 10
        icon_name = 'low'
      else
        icon_name = 'critical'
      end

      time_info = 'Charging'

      if is_charging
        if time_to_full == 65535
          time_info = 'Calculating...'
        else
          time_info = "#{time_to_full} min until Full"
        end
      else
        if fully_charged
          if is_external
            time_info = 'On AC Power'
            icon_name = 'power'
          else
            time_info = "#{time_to_empty} min Left"
          end
        else
          time_info = "#{time_to_empty} min Left"
        end
      end

      if is_charging
        status_info = "Charging"
      elsif fully_charged
        status_info = 'Fully Charged'
      else
        status_info = "Draining"
      end

      icon = {:type => "default", :name => "icon/battery/#{icon_name}.png"}

      battery_item = {
        :title        => "#{status_info}, #{time_info}"            ,
        :subtitle     => "#{percentage_sign(percent)} #{percent}%" ,
        :uid          => "Battery: #{serial}"                      ,
        :valid        => 'no'                                      ,
        :autocomplete => 'Battery ⟩ '                              ,
        :icon         => icon                                      ,
      }

      if show_detailed_feedback
        battery_item[:valid] = 'yes'
        battery_item[:title] = status_info

        @feedback.add_item(battery_item)

        @feedback.add_item(
          :title => "#{time_info}",
          :subtitle => 'Time',
          :icon => {:type => "default", :name => "icon/battery/clock.png"}
        )
        @feedback.add_item(
          :title => "#{temperature}° C",
          :subtitle => 'Temperature',
          :icon => {:type => "default", :name => "icon/battery/temp.png"}
        )
        @feedback.add_item(
          :title => "#{cycle_count} Cycles",
          :subtitle => 'Charge Cycles',
          :icon => {:type => "default", :name => "icon/battery/cycles.png"}
        )
        @feedback.add_item(
          :title => "#{health}%",
          :subtitle => 'Health',
          :icon => {:type => "default", :name => "icon/battery/health.png"}
        )
        @feedback.add_item(
          :title => "#{serial}",
          :subtitle => 'Serial Number',
          :match? => :all_title_match?,
          :icon => {:type => "default", :name => "icon/battery/serial.png"}
        )
        @feedback.add_item(
          :title => "#{age.round} months",
          :subtitle => 'Age',
          :icon => {:type => "default", :name => "icon/battery/age.png"}
        )
      else
        airpods_battery()
        @feedback.add_item(battery_item)
      end
    end

  end

  private

  def airpods_battery
    battery_info_raw = %x{bash ./bin/AirPodsPower.sh}
    return if battery_info_raw.include?("Not Connected")

    icon = {:type => "default", :name => "icon/battery/airpods-3.png"}
        battery_info = battery_info_raw
          .strip
          .gsub(" ", "")
          .split("%")
          .select{|el|
            el.split(":")[1] != "0"
          }
          .map{|el| el+"%"}.join(", ")
          .gsub("L:", "Left :")
          .gsub("R:", "Right :")
          .gsub("C:", "Case :")

        airpods_battery_item = {
          :title        => "Airpods"            ,
          :subtitle     => "#{battery_info}" ,
          :uid          => "Airpods"                      ,
          :valid        => 'no'                                      ,
          :autocomplete => 'Airpods ⟩ '                              ,
          :icon         => icon                                      ,
        }
        @feedback.add_item(airpods_battery_item)
  end

  def percentage_sign(percent, use_sign = :emoji)
    if use_sign.eql? :emoji
      full = '🔴'
      empty = '⚪'
    elsif use_sign.eql? :plain
      full = '●'
      empty = '○'
    elsif use_sign.eql? :fruit
      signs = ["🍎", "🍎", "🍎", "🍊", "🍊", "🍊", "🍏" , "🍏", "🍏", "🍏", "🍏"]
      mark = percent / 10
      return signs[0...mark].join
    end
    mark = percent / 10
    sign = ''
    mark.times { |_| sign += full }
    (10 - mark).times { |_| sign += empty }
    sign
  end

end
def generate_feedback(alfred, query)
  eye = Glance.new(alfred, query)
  eye.collect

  puts alfred.feedback.to_alfred(Glance.with_query(query))
end


if __FILE__ == $PROGRAM_NAME
  Alfred.with_friendly_error do |alfred|
    alfred.with_rescue_feedback = true
    generate_feedback(alfred, ARGV)
  end
end
