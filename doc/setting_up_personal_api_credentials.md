# API Credentials

Superset API Credentials are essentially the username and password of the Superset host users account.

If you know these already, plug them and your host value into the `.env` and it should all just work.  A sample env.sample is provided as a template. 

Create your own .env file with  
`cp env.sample .env`

Adjust .env as required.
```
ENV['SUPERSET_HOST'] = "https://your-superset-host.com"
ENV['SUPERSET_API_USERNAME']="your-username"
ENV['SUPERSET_API_PASSWORD']="your-password"
```

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

Create your `.env`
Add your username and password to the `.env` file.

