# S3Server

Simple file server providing anyone with a password access to an S3 bucket's files. 
Displays files and provides download links for each file that expire.


## Configration

1. Register a Google app and get the secret keys. The callback URL for this app should be `/login/google`
2. Get an S3 account set up
3. Create a `.env` file with the following contents:

    ```
    GOOGLE_ID=your_app_id
    GOOGLE_SECRET=your_google_secret
    S3_BUCKET=your_bucket
    S3_ID=your_app_id
    S3_KEY=your_key
    S3_LINK_TIMEOUT=5
    S3_REGION=us-west-2
    ```

4. Run the app with `puma`

5. To restrict people, create the file `acl.txt` and place the emails of the people you want to allow. Add one email per line. Then place the file in the S3 bucket you want to protect. 

In production, set the environment variables on your server.
