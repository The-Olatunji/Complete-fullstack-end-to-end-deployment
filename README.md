# climate-monitor-gads

Climate Change Monitor Tracker 

Overview 

Project to measure air pollution in the atmosphere per time

Tasks

1 - Find and Fetch reliable Climate air pollution data from an API  - done 

2 - Build simple app to measure air pollution based on geolocation by: 
 - fetch latitude and longitude location data based on city that user inputs - done
 - return air pollution index data and recommendation - done
 - create a simple html/ frontend to interact with data - #done
 
3 - test for functionality - #done

4 - Package as flask app and make available on docker as image that anyone can pull and run - #done

 1. Ingress Controller
For Ingress to be available for use, an ingress controller in needed to implement the ingress resource which will be created. Popular choice include Traefix, nginx. *In this case my most preferred choice is NGINX ingress controller*.
Run ` kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml ` to deploy the NGINX controller manifest.