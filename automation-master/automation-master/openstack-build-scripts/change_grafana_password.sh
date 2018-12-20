sleep 1m
curl -v -X PUT -H "Content-Type: application/json" -d '{
  "oldPassword": "admin",
  "newPassword": "52T8FVYZJse",
  "confirmNew": "52T8FVYZJse"
}' --insecure https://admin:admin@127.0.0.1:3000/api/user/password
