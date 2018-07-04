# System Monitor : An Alfred 3 Workflow.

### Take a glance at system performance. List/Kill Top Processes by Memory, Cpu or IO Usage.

###### Forked from Zhao Cai as Alfred 2 Top Workflow at https://github.com/zhaocai/alfred2-top-workflow




### [💾 Download](https://github.com/cgjosephlee/system-monitor-alfred-workflow/releases/latest)

- 1) List/Kill Top Processes by Memory/CPU/IO Usage

<p align="center">
   <img src="https://github.com/singhprd/alfred2-top-workflow/blob/master/screenshots/mixed%20top%20processes.png" height="500">
</p>

- 2) Get a glance of system status including internal battery, fan speed, CPU/GPU Temperature, bluetooth battery, disk capacity, etc.

<p align="center">
   <img src="https://github.com/singhprd/alfred2-top-workflow/blob/master/screenshots/glance.png" height="400">
</p>

## Usage

### 0. Show Help 

Just type `-?`, `-h`, or `--help` after the keyword to show help.

<p align="center">
   <img src="https://github.com/singhprd/alfred2-top-workflow/blob/master/screenshots/help.png" height="400">
</p>

### 1. Top Processes

#### A. Keywords:

##### 1.) `top`: Show a mixed processes list based on top cpu/memory usage.


###### 1. `top -m`, `top --memory` to show processes ranked by memory usage

###### 2. `top -c`, `top --cpu`, to show processes ranked by cpu usage

###### 3. `top -i`, `top --io`, to show processes ranked by io usage with **callback** from top io trace collector.

   Top IO requires [DTrace][Dtrace] and it would take a while to finish. The new **callback** design is to run the job in he background and post a notification (OSX 10.8+) using notification center. Click on the notification to show the result in alfred.

![](https://raw.github.com/zhaocai/alfred2-top-workflow/master/screenshots/callback.png) 



###### **Modifier Key**

   - `none`    : The default action is to list files opened by process ID
   - `control` : Kill the selected process
   - `command` : kill forcefully (`kill -9`)
   - `alt`     : Nice (lower) the selected process's cpu priority
   - `shift`   : Search web for process information


##### 2.) `kill`: Filter process to kill.

###### **Modifier Key**

   - `none`: The default action is to kill by process ID
   - `command` : kill forcefully (`kill -9`)

##### 3.) `lsof`: List files opened by process id

###### **Modifier Key**

   - `none`: The default action is to reveal file in Finder

#### B. Filter by Query

##### 1.) Type process name to filter

<p align="center">
   <img src="https://github.com/singhprd/alfred2-top-workflow/blob/master/screenshots/filtered%20by%20query.png" width="400">
</p>


##### 2.) To search for process state, use **:idle**, **:sleep**, **:stopped**, **:zombie**, **:uninterruptible**, **:runnable**, etc.

<p align="center">
   <img src="https://github.com/singhprd/alfred2-top-workflow/blob/master/screenshots/top_sleep.png" height="400">
</p>

### 2. Glance an Eye on your system

#### A. Keywords:

1. `glance`: Show system information including internal battery, bluetooth battery, disk capacity, etc.

<p align="center">
   <img src="https://github.com/singhprd/alfred2-top-workflow/blob/master/screenshots/battery_2.png" height="400">
</p>

#### B. Change Display Order

1. Activate `Alfred Preferences` → `Advanced` → `Top Result Keyword Latching`

    ![](https://raw.github.com/zhaocai/alfred2-top-workflow/master/screenshots/Alfred_Preferences_Learning.png)

2. Hit `Enter` for the feedback item you wish to show up on the top.



## Installation

Two ways are provided:

1. You can download the latest release from [here](https://github.com/singhprd/system-monitor-alfred-workflow/releases) and import into to Alfred. This method is suitable for **regular users**.

2. You can `git clone` or `fork` this repository and use `rake install` and `rake uninstall` to install. Check `rake -T` for available tasks.
This method create a symlink to the alfred workflow directory: "~/Library/Application Support/Alfred 3/Alfred.alfredpreferences/workflows". This method is suitable for **developers**.


---

### Forked from Zhao Cai at https://github.com/zhaocai/alfred2-top-workflow
