# API Credentials

Superset API Credentials are essentially the username and password of the Superset host users account.

If you know these already, plug them and your host value into the `.env` and it should all just work.  A sample env.sample is provided as a template. 

Create your own .env file with  
`cp env.sample .env`

Adjust .env as required.
```
SUPERSET_HOST="https://your-superset-host.com"
SUPERSET_API_USERNAME="your-username"
SUPERSET_API_PASSWORD="your-password"
```

If you have multiple superset hosts across various environments you also have the option
to create individual env files per environment.  More details below.

## What is my user name?

If your Superset instance is setup to authenicate via SSO then your authenticating agent will most likely have provided a username for you in the form of a UUID value.

This is easily retrieved on you User Profile page in Superset.

Optionally use jinja template macro in sql lab.

`select ' {{ current_username() }}' as user_id;`

## Creating / Updating your password via Swagger interface

A common setup is to use SSO to enable user access in Superset.  This would mean your authenticating agent is your SSO provider service ( ie Azure ) and most likely you do not have / need a password configured for your Superset user for GUI access.

If this is the case, you will need to add your own password via hitting the superset API using the swagger interface.

Firstly you will need your superset user id, which is the superset users table PK that is assigned to you.

It appears this user id value is not exposed on the Users profile page in Superset. Depending on your level of access within your Superset instance you could:
- access the Users List page, find your user, and mouse over the edit button to reveal the Url and user id param value.  
- got to sql lab and use a jinja template predefined macro to retrieve your users id.
`select ' {{ current_user_id() }}' as user_id;`
- ask your superset admin to tell you what your personal superset user id is.

Once you have your user id value, open the Swagger API page on you superset host.  
`https://{your-superset-host}/swagger/v1`

Scroll down to the 'Security Users' area and find the PUT request that will update your users record.

PUT `/api/v1/security/users/{pk}`

Click 'Try it Out' and add your users ID in the PK input box.  

Edit the params to only consist of only the password field and the value of your new password.  

```
{
  "password": "{some-long-complex-random-password-value}"
}
```

And click Execute.

Within your `.env` now add your username and password.

# Accessing API across Multiple Environments

Given some local development requirements where you have to access multiple superset hosts across various environments with different credentials you can setup the env creds as follows.

Just set the overall superset environment in `.env`

```
# .env file holding one setting for the overall superset environment
SUPERSET_ENVIRONMENT='staging'
```

Then create a new file called `.env-staging` that holds your superset staging host and credentials.

```
# specific settings for the superset staging host
SUPERSET_HOST="https://your-staging-superset-host.com"
SUPERSET_API_USERNAME="staging-user-here"
SUPERSET_API_PASSWORD="set-password-here"
```

Do the same for production env.  
Create a new file called `.env-production` that holds your superset production host and credentials.

```
# specific settings for the superset production host
SUPERSET_HOST="https://your-production-superset-host.com"
SUPERSET_API_USERNAME="production-user-here"
SUPERSET_API_PASSWORD="set-password-here"
```

The command `bin/console` will then load your env file depending on the value in ENV['SUPERSET_ENVIRONMENT'] from the primary `.env`.

When you need to switch envs, exit the console, edit the .env to your desired value, eg `production`, then open a console again.

Bonus is the Pry prompt will now also include the `SUPERSET_ENVIRONMENT` value.

```
bin/console
ENV configuration loaded from from .env-staging
[1] (ENV:STAGING)> Superset::Dashboard::List.new(title_contains: 'video').list

Happi: GET https://your-staging-superset-host.com/api/v1/dashboard/?q=(filters:!((col:dashboard_title,opr:ct,value:'video')),page:0,page_size:100), {}
+----+------------------+-----------+------------------------------------------------------------------+
|                                      Superset::Dashboard::List                                       |
+----+------------------+-----------+------------------------------------------------------------------+
| Id | Dashboard title  | Status    | Url                                                              |
+----+------------------+-----------+------------------------------------------------------------------+
| 6  | Video Game Sales | published | https://your-staging-superset-host.com/superset/dashboard/6/ |
+----+------------------+-----------+------------------------------------------------------------------+
```




