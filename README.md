
```
Pranavs-MacBook-Pro:devops pranav$ ./devops.rb

USAGE:
===========================

  ./devops.rb app_name task

  where
    app_name    :   name of the app or hostname to be worked upon. This name
                    should be a valid hostname is the ansible hosts file
    task        :   task can be one of the following tasks to be performed
                    on the app_name. Tasks can not be chained and only one
                    task can be executed at a time.

                    The tasks can be one of the following:
                        - ["setup", "deploy", "restart"]

NOTE:
=========================
  * By default it uses the hosts file present in the present directory
```

# READ hosts file  first


# Deploy Enterprise Dashboard

Deploy `enterprise_dashboard` example

```
./devops.rb enterprise_dashboard deploy
```

# Deploy API Consumer

```
./devops.rb api_consumer deploy
```

# Deploy API Handler

```
./devops.rb api_handler deploy
```

# Deploy Recurring Gobs

```
./devops.rb recurring_jobs deploy
```


```
ansible-playbook -i devops/hosts devops/deploy/enterprise_dashboard.yml --private-key ~/workspace/octo/web.pem -u ubuntu -v
```
