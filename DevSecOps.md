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

# Module 3 - Install SonarQube

``` Bash
sudo sysctl -w vm.max_map_count=262144
```

``` yaml
version: "3.8"

services:
  sonarqube:
    image: sonarqube:lts-community
    depends_on:
      - sonar_db
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://sonar_db:5432/sonar
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: sonar
    ports:
      - "9000:9000"
    volumes:
      - sonarqube_conf:/opt/sonarqube/conf
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
      - sonarqube_temp:/opt/sonarqube/temp

  sonar_db:
    image: postgres:13
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar
      POSTGRES_DB: sonar
    volumes:
      - sonar_db:/var/lib/postgresql
      - sonar_db_data:/var/lib/postgresql/data

volumes:
  sonarqube_conf:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
  sonarqube_temp:
  sonar_db:
  sonar_db_data:
```

# Module 4 - Install Defect Dojo

``` Bash
# Download Defect Dojo repository
git clone https://github.com/DefectDojo/django-DefectDojo

# Go to Defect Dojo repository
cd django-DefectDojo

# Build Docker Compose
sudo docker-compose build

# Run Docker Compose
sudo docker-compose up -d

# Get admin credentials. The initializer can take up to 3 minutes to run
docker-compose logs initializer | grep "Admin password:"

# Run docker-compose logs to track the progress
docker-compose logs -f
```

# Module 5 - Configure GitLab pipeline

## DevSecOps Tools

| Commit | Secrets | SAST | Quality | Dependency | DAST | Aggregates |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|Branch Name Lint | GitLeaks | Bearer | SonarQube | Dependency Track | OWASP ZAP | Defect Dojo
| | TruffleHog | | | Trivy | | Dependency Track


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
# TODO: Branch-Name-Lint, CodeQL, Dependency Track, OWASP ZAP, Trivy
# READY: GitLeaks, TruffleHog, CycloneDX, Bearer, SonarQube, Defect Dojo, Dependency Check
stages:
  - commit
  - secrets
  - sast
  - quality
  - dependency
  - dast
  - aggregates

before_script:
    - export FORMATTED_DATE="$(date -d "$CI_JOB_STARTED_AT" +"%Y-%m-%d")"

cache:
  paths:
    - node_modules/

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

sonarqube:
  stage: quality
  image: sonarsource/sonar-scanner-cli:latest
  script:
    - sonar-scanner -Dsonar.projectKey=$CI_PROJECT_NAME -Dsonar.sources=. -Dsonar.host.url=$SONAR_HOST_URL -Dsonar.login=$SONAR_TOKEN
    - 'curl -u $SONAR_TOKEN: "https://$SONAR_HOST_URL/api/issues/search?componentKeys=$CI_PROJECT_NAME&resolved=false" -o sonarqube-report.json'
  allow_failure: true

dependency_check:
  stage: dependency
  image:
    name: owasp/dependency-check:latest
    entrypoint: [""]
  script:
    - /usr/share/dependency-check/bin/dependency-check.sh --scan . --format JSON --project "$CI_PROJECT_NAME" --out dependency-check-report.json
  artifacts:
    paths:
      - dependency-check-report.json
    reports:
      dependency_scanning: dependency-check-report.json
    when: always
  allow_failure: true

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

defectdojo:
  stage: aggregates
  image: python:3.9-bullseye
  script:

  # Truffle Hog
    - 'curl -v -X POST "$DEFECT_DOJO_URL/api/v2/import-scan/"
    -H "accept: application/json"
    -H "Content-Type: multipart/form-data"
    -H "Authorization: Token $DEFECT_DOJO_TOKEN"
    -F "minimum_severity=Info"
    -F "active=true"
    -F "verified=true"
    -F "scan_type=Trufflehog Scan"
    -F "file=@trufflehog-report.json"
    -F "close_old_findings=true"
    -F "product_name=$CI_PROJECT_NAME"
    -F "scan_date=$FORMATTED_DATE"
    -F "engagement_name=$CI_PROJECT_NAME"
    -F "auto_create_context=true"
    -F "product_type_name=Web"'
  
  # GitLeaks
    - 'curl -v -X POST "$DEFECT_DOJO_URL/api/v2/import-scan/"
    -H "accept: application/json"
    -H "Content-Type: multipart/form-data"
    -H "Authorization: Token $DEFECT_DOJO_TOKEN"
    -F "minimum_severity=Info"
    -F "active=true"
    -F "verified=true"
    -F "scan_type=Gitleaks Scan"
    -F "file=@gitleaks-report.json"
    -F "close_old_findings=true"
    -F "product_name=$CI_PROJECT_NAME"
    -F "scan_date=$FORMATTED_DATE"
    -F "engagement_name=$CI_PROJECT_NAME"
    -F "auto_create_context=true"
    -F "product_type_name=Web"'
  
  # Bearer
    - 'curl -v -X POST "$DEFECT_DOJO_URL/api/v2/import-scan/"
    -H "accept: application/json"
    -H "Content-Type: multipart/form-data"
    -H "Authorization: Token $DEFECT_DOJO_TOKEN"
    -F "minimum_severity=Info"
    -F "active=true"
    -F "verified=true"
    -F "scan_type=Bearer CLI"
    -F "file=@bearer-report.json"
    -F "close_old_findings=true"
    -F "product_name=$CI_PROJECT_NAME"
    -F "scan_date=$FORMATTED_DATE"
    -F "engagement_name=$CI_PROJECT_NAME"
    -F "auto_create_context=true"
    -F "product_type_name=Web"'
  
  # CycloneDX
    - 'curl -v -X POST "$DEFECT_DOJO_URL/api/v2/import-scan/"
    -H "accept: application/json"
    -H "Content-Type: multipart/form-data"
    -H "Authorization: Token $DEFECT_DOJO_TOKEN"
    -F "minimum_severity=Info"
    -F "active=true"
    -F "verified=true"
    -F "scan_type=CycloneDX Scan"
    -F "file=@cyclonedx-report.json"
    -F "close_old_findings=true"
    -F "product_name=$CI_PROJECT_NAME"
    -F "scan_date=$FORMATTED_DATE"
    -F "engagement_name=$CI_PROJECT_NAME"
    -F "auto_create_context=true"
    -F "product_type_name=Web"'
  
  # Dependency Check
    - 'curl -v -X POST "$DEFECT_DOJO_URL/api/v2/import-scan/"
    -H "accept: application/json"
    -H "Content-Type: multipart/form-data"
    -H "Authorization: Token $DEFECT_DOJO_TOKEN"
    -F "minimum_severity=Info"
    -F "active=true"
    -F "verified=true"
    -F "scan_type=Dependency Check Scan"
    -F "file=@dependency-check-report.json"
    -F "close_old_findings=true"
    -F "product_name=$CI_PROJECT_NAME"
    -F "scan_date=$FORMATTED_DATE"
    -F "engagement_name=$CI_PROJECT_NAME"
    -F "auto_create_context=true"
    -F "product_type_name=Web"'
  
  # SonarQube
    - 'curl -v -X POST "$DEFECT_DOJO_URL/api/v2/import-scan/"
    -H "accept: application/json"
    -H "Content-Type: multipart/form-data"
    -H "Authorization: Token $DEFECT_DOJO_TOKEN"
    -F "minimum_severity=Info"
    -F "active=true"
    -F "verified=true"
    -F "scan_type=SonarQube Scan"
    -F "file=@sonarqube-report.json"
    -F "close_old_findings=true"
    -F "product_name=$CI_PROJECT_NAME"
    -F "scan_date=$FORMATTED_DATE"
    -F "engagement_name=$CI_PROJECT_NAME"
    -F "auto_create_context=true"
    -F "product_type_name=Web"'
```