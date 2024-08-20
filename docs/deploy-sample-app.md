# Example sample app deployment to downstream cluster

## Deploy

A sample repo was added in demo1 cluster **Explore -> Apps -> Repositories**  
Find an app using the Apps Charts search and click **Install**  
![downstream-cluster-app-deploy](../assets/downstream-cluster-app-deploy.png)  

The application components and be explored and the app accessed via the Service (or Ingress if configured)  
![downstream-cluster-app-ingress](../assets/downstream-cluster-app-ingress.png)  

Note when accessing a NodePort service the service is proxied be the Rancher Manager web app by default:  
![downstream-cluster-app-proxy-ingress](../assets/downstream-cluster-app-proxy-ingress.png)  

