# Synology

## Install service as a scheduled task

1. Add directory in **File station** in path `/volume1/docker/<user-name>/<service-app>`

2. Goto **Control panel** in DSM

3. Click **Task scheduler**

4. Create "Scheduled task/User-defined script"

5. In "General/settings" tab, enter **Task** name: `<service-name>` and choose **Root** user

6. In "Schedule/date" tab, check **Run on the following date**, start: 20250330, repeat: Do not repeat

7. In "Task settings" tab, add script to install `<service-name>`.
