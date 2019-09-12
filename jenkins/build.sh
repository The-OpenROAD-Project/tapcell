docker build -f jenkins/Dockerfile.dev -t tapcell .
docker run -v $(pwd):/tapcell tapcell bash -c "./tapcell/jenkins/install.sh"