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