$http = [System.Net.HttpListener]::new()
$http.Prefixes.Add("http://+:5000/")
$http.Start()
if ($http.IsListening) {
  Write-Host "HTTP server started."
}
while ($http.IsListening) {
  $context = $http.GetContext()
  if ($context.Request.HttpMethod -eq 'GET') {
    Write-Host "$($context.Request.UserHostAddress) => $($context.Request.Url)"
    [string]$html =  "<html>"
    [string]$html += "<head>"
    [string]$html += "<style> body { background-color: #008AD7; color: #FFF; } </style>"
    [string]$html += "</head>"
    [string]$html += "<body>"
    [string]$html += "<h1>Windows Kubernetes</h1>"
    [string]$html += "<p>Hello world from PowerShell!</p>"
    [string]$html += "</body>"
    [string]$html += "</html>"
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
    $context.Response.ContentLength64 = $buffer.Length
    $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $context.Response.OutputStream.Close()
  }
}