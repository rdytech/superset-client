# API Credentials

Superset API Credentials are essentially the username and password of the Superset host users account.  
If you know these already, plug them into the `.env` and it should all just work. 


## My Superset Host is set to authenticate with SSO ...

which then would mean your authenticating agent is your SSO provider service ( ie Azure ) and  
most likely you do not have / need a password configured for your user.

If this is the case, you will need to create your own password via hitting the superset API using the swagger interface.

Firstly you will need your superset user details, particulary your id, which is the superset users table PK that is assigned to you.
It appears this is not exposed on the Users profile page and you may need assistance from an admin to get your personal User Id value.

Once you have your user id value, open the Swagger API page on you superset host.  https://{your-superset-host}/swagger/v1

- Scroll down to the 'Security Users' area and find the PUT request for `/api/v1/security/users/{pk}`
- Click 'Try it Out'
- Add your users ID
- edit the params to only consist of only the password field and the value of your new password.  

```
{
  "password": "nsrI8d2fEkIf3B7oJSZ4ca*ATaqCq7z9PY#x"
}
```

And click Execute.

