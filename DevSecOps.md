# Module 0 - Install Docker and Docker Compose
``` Bash
sudo apt-get update
sudo apt-get install docker
sudo apt-get install docker-compose
```

# Module 1 - Install GitLab CE and GitLab Runnes

## Check the IP address range of the 'enp0s3' (ex. 10.0.2.15)
``` Bash
ip addr show
```

## Prepare the Docker Compose
[GitLab & GitLab Runner Docker Compose](./Platforms/GitLab/docker-compose.yml)

## Run docker-compose.yml
``` Bash
sudo docker-compose up -d
```

## Reset GitLab administrator password
``` Bash
sudo docker exec -it gitlab bash
gitlab-rake "gitlab:password:reset[root]"
```

# Module 2 - Configure GitLab Runner
``` Bash
# Get list of running docker instances
sudo docker ps -a

# Enter to the docker container
sudo docker exec -it <docker_id> bash

# Register the GitLab runner
gitlab-runner register --url http://10.0.2.15 --token <gitlab_runner_token>
```

# Module 3 - Install SonarQube
## Modify the value of parameter "vm.max_map_count"
``` Bash
sudo sysctl -w vm.max_map_count=262144
```
## Prepare the Docker Compose
[SonarQube Docker Compose](./Platforms/SonarQube/docker-compose.yml)

# Module 4 - Install Defect Dojo

## Run the commands
[Defect Dojo Commands](./Platforms/DefectDojo/commands.sh)

# Module 5 - Configure GitLab pipeline

## DevSecOps Tools

| Commit | Secrets | SAST | Quality | Dependency | DAST | Aggregates |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|Branch Name Lint | GitLeaks | Bearer | SonarQube | Dependency Track | OWASP ZAP | Defect Dojo
| | TruffleHog | | | Trivy | | Dependency Track


## 1. Test the CI/CD pipeline
[Dummy 1 GitLab CI/CD](./Pipeline/dummy-1-gitlab-ci.yml)

## 2. Prepare the schema of secure pipeline
[Dummy 2 GitLab CI/CD](./Pipeline/dummy-2-gitlab-ci.yml)

## 3. Final CI/CD pipeline
[Final GitLab CI/CD](./Pipeline/gitlab-ci.yml)