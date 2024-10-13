# Module 0 - Install Docker and Docker Compose
``` Bash
sudo apt-get update
sudo apt-get install docker
sudo apt-get install docker-compose
```

# Module 1 - Install GitLab CE and GitLab Runnes

``` Bash
# Check the IP address range of the 'enp0s3' (ex. 10.0.2.15)
ip addr show
```
## docker-compose.yml
``` yaml
version: '3.8'
services:

  # GitLab
  gitlab:
    image: 'gitlab/gitlab-ce:latest'
    restart: always
    container_name: gitlab
    hostname: '10.0.2.15'  # hostname need to be local IP address, because GitLab runners needs to use that. Cannot be "localhost", because each docker instance has own "localhost".
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://10.0.2.15'
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - './gitlab/config:/etc/gitlab'
      - './gitlab/logs:/var/log/gitlab'
      - './gitlab/data:/var/opt/gitlab'
    networks:
      - gitlab-network

  # GitLab Runner
  gitlab-runner-1:
    image: gitlab/gitlab-runner:alpine
    restart: always
    container_name: gitlab-runner-1
    hostname: gitlab-runner-1
    depends_on:
      - gitlab
    volumes:
     - ./config/gitlab-runner:/etc/gitlab-runner
     - /var/run/docker.sock:/var/run/docker.sock
    networks:
        - gitlab-network

networks:
  gitlab-network:
    name: gitlab-network
```

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
gitlab-runner register --url http://10.0.2.15 --token glrt-ibQfDVjFs4V8eb7NAs9s
```

# Module 3 - Configure GitLab pipeline

## 1. Test the CI/CD pipeline
``` yml
stages:
  - test

test-job:
  stage: test
  script:
    - echo "Testing runner"
```

## 2. Prepare the schema of secure pipeline
``` yml
stages:
  - commit
  - secrets
  - sast
  - quality
  - dependency
  - dast
  - aggregates

branch-name-lint-job:
  stage: commit
  script:
    - echo "Branch Name Lint"

gitleaks-job:
  stage: secrets
  script:
    - echo "GitLeaks"

trufflehog-job:
  stage: secrets
  script:
    - echo "TruffleHog"

bearer-job:
  stage: sast
  script:
    - echo "Bearer"

codeql-job:
  stage: sast
  script:
    - echo "CodeQL"

sonarqube-job:
  stage: quality
  script:
    - echo "SonarQube"

dependency-check-job:
  stage: dependency
  script:
    - echo "Dependency Check"

cyclonedx-job:
  stage: dependency
  script:
    - echo "CycloneDX"

trivy-job:
  stage: dependency
  script:
    - echo "Trivy"

owasp-zap-job:
  stage: dast
  script:
    - echo "OWASP ZAP"

dependency-track-job:
  stage: aggregates
  script:
    - echo "Dependency Track"

defect-dojo-job:
  stage: aggregates
  script:
    - echo "Defect Dojo"
```


## 3. Ready CI/CD pipeline
``` yml
# TODO: Branch-Name-Lint, CodeQL, SonarQube, Dependency Check, Dependency Track, Defect Dojo, OWASP ZAP, Trivy,
# READY: GitLeaks, TruffleHog, CycloneDX, Bearer
stages:
  - commit
  - secrets
  - sast
  - quality
  - dependency
  - dast
  - aggregates

branch-name-lint-job:
  stage: commit
  script:
    - echo "Branch Name Lint"

gitleaks:
  stage: secrets
  image:
    name: zricethezav/gitleaks:latest
    entrypoint: [""]
  script:
    - gitleaks detect --source . --report-path gitleaks-report.json
  artifacts:
    paths:
      - gitleaks-report.json
    reports:
      secret_detection: gitleaks-report.json
    when: always
  allow_failure: true

trufflehog-job:
  stage: secrets
  image: 
    name: docker.io/trufflesecurity/trufflehog:latest
    entrypoint: [""]
  script:
    - trufflehog filesystem --json . > trufflehog-report.json
  artifacts:
    paths:
      - trufflehog-report.json
    reports:
      secret_detection: trufflehog-report.json
    when: always
  allow_failure: true

bearer:
  stage: sast
  image: 
    name: bearer/bearer
    entrypoint: [""]
  script:
    - bearer scan . --format json --output bearer-report.json
  artifacts:
    paths:
      - bearer-report.json
    reports:
      sast: bearer-report.json
    when: always
  allow_failure: true

codeql-job:
  stage: sast
  script:
    - echo "CodeQL"

sonarqube-job:
  stage: quality
  script:
    - echo "SonarQube"

dependency-check-job:
  stage: dependency
  script:
    - echo "Dependency Check"

cyclonedx:
  stage: dependency
  image: 
    name: node:lts
  script:
    - npm install
    - npm install --global @cyclonedx/cyclonedx-npm
    - cyclonedx-npm --output-format json --output-file cyclonedx-report.json
  artifacts:
    paths:
      - cyclonedx-report.json
    reports:
      dependency_scanning: cyclonedx-report.json
    when: always
  allow_failure: true

trivy-job:
  stage: dependency
  script:
    - echo "Trivy"

owasp-zap-job:
  stage: dast
  script:
    - echo "OWASP ZAP"

dependency-track-job:
  stage: aggregates
  script:
    - echo "Dependency Track"

defect-dojo-job:
  stage: aggregates
  script:
    - echo "Defect Dojo"
```