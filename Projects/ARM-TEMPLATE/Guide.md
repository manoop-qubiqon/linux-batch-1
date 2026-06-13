# How to Deploy an ARM Template via Azure Portal

## Step 1: Log in to the Azure Portal
- Open your web browser and navigate to [Azure Portal](https://portal.azure.com).
- Sign in using the Azure account credentials provided for the lab.

## Step 2: Access the "Deploy a Custom Template" Feature
- In the Azure Portal, use the search bar at the top to type **"Deploy a custom template"**.
- Select **"Deploy a custom template"** from the search results.

## Step 3: Create Your Template
- You'll be directed to the **"Custom deployment"** page.
- Click on **"Build your own template in the editor"**.
- I have created a template for you named `deploy-custom-template.json` located below the guide.md,  Please copy and paste your ARM template JSON code into the provided editor.
- Click **"Save"** to proceed.

## Step 4: Set Up the Deployment
On the next screen, fill in the required details:

- **Subscription**: Select the Azure subscription to use. This will be auto-populated for you.
- **Resource Group**: Choose an existing resource group with a name starting with `your`.
- **Region**: Select the region where your resources will be deployed. The system will auto-suggest and fill in this field for you, but make sure to verify it to avoid deployment failures.
- If your template includes parameters, you will be prompted to enter values (e.g., resource names, locations, or SKU types).

> **Note:** One parameter for the Storage Account is predefined.
> - **StorageAccountName**: Choose a name for the storage account in the format `word + numbers`.

## Step 5: Review and Validate Your Template
- After completing all the required fields, click **"Review + create"**.
- Azure will validate your template. If there are any issues or missing fields, you'll receive a notification to make corrections.

## Step 6: Deploy Your Template
- Once the validation is successful, a summary of your deployment settings will appear.
- Click **"Create"** to initiate the deployment.
- Azure will start deploying the resources as specified in your ARM template.

## Step 7: Monitor the Deployment
- You will be taken to the deployment status page, where you can track the progress of your deployment.
- After the deployment is complete, you'll receive a notification, and the status will show as **"Succeeded"**.

## Step 8: Verify the Deployment
- After the deployment, navigate to the resource group in the Azure Portal to ensure all resources have been deployed correctly.
- Finally, click on the **"Check"** button to complete the process.

---

This streamlined process allows you to deploy ARM templates directly through the Azure Portal, providing an easy way to manage and monitor your deployments.