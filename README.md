
```
ansible-playbook -i devops/hosts devops/deploy/enterprise_dashboard.yml --private-key ~/workspace/octo/web.pem -u ubuntu -v
```

# Deploy Example

Deploy `enterprise_dashboard` example

```
./devops.rb enterprise_dashboard deploy
```

Wait for some time. It does not show streaming output. The output shall be displayed once the command is executed.
