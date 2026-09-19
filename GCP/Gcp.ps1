# Obtain an OAuth2 access token using the gcloud CLI: #https://shell.cloud.google.com/?theme=system&fromcloudshell=true&show=terminal
gcloud auth print-access-token
$token = '<>'

#region
$headers = @{Authorization = "Bearer $token"; Accept  = "application/json"}
# Handle pagination so you get all projects
$projects = (Invoke-RestMethod -Method Get -Uri "https://cloudresourcemanager.googleapis.com/v1/projects?pageSize=1000" -Headers $headers).projects

$Projects | Select-Object projectId, name, projectNumber, lifecycleState | Sort-Object projectId | Format-Table -AutoSize
#endregion


#region
$scope = "projects/test-50889"                                                          # Define the target scope              

$uri = "https://cloudasset.googleapis.com/v1/$($scope):searchAllResources"              # Define the REST API endpoint

$response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
$response.results |Select-Object assetType, displayName, location,state,parentAssetType |Format-Table -AutoSize 
#endregion


#region Delete project
$projectId = "test-50889"
$uri = "https://cloudresourcemanager.googleapis.com/v1/projects/$projectId"

# Correct call: HTTP DELETE, no request body
$result = Invoke-RestMethod -Method Delete -Uri $uri -Headers $headers
$result
#endregion