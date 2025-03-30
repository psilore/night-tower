# Docker

## Install service in NAS

1. Add directory in **File station** in path `/volume1/docker/<user-name>/<service-app>`

2. Goto **Control panel** in DSM

3. Click **Task scheduler**

4. Create "Scheduled task/User-defined script"

5. In "General/settings" tab, enter **Task** name: "Install Flame" and choose **Root** user

6. In "Schedule/date" tab, check **Run on the following date**, start: 20250330, repeat: Do not repeat  

7. In "Task settings" tab, add script to install Flame.  
   For more options see [Flame installation](https://github.com/pawelmalak/flame?tab=readme-ov-file#installation)

> [!NOTE]
> Change <password> that is passed as enviroment variable to the image!

   **Script:**  

   ```bash
   docker run -d \
     --name=flame \
     --publish 5210:5005 \
     --volume /volume1/docker/viggo/flame:/app/data \
     --volume /var/run/docker.sock:/var/run/docker.sock \
     --env PASSWORD=<password> \
     --restart always \
     pawelmalak/flame
   ```
