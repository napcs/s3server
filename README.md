# S3Server

Simple file server providing restricted access to an S3 bucket's files. 
Displays files and provides download links for each file that expire.

## How it works

When a user visits the app, they are redirected to log in with their Google account. Once logged in, the application looks for a file in the S3 bucket called `acl.txt` for the email of the logged in user. If their email exists in the file, they get in. This eliminates the requirement for a database and makes sharing a bucket of files simple.

## Limitations

Currently, this server only handles a single bucket's contents up to 1000 elements, and cannot support folders within a bucket. This is designed to share a specific set of resources quickly.

## Requirements

1. An S3 bucket with credentials.
2. (Optional) A Google account with credentials

## Configration

You can use password authentication or Google authentication to allow access to your bucket.

In both cases, first identify the S3 bucket and region you want to use. Ensure you have the ID and access key for the bucket before proceeding.

### Configuring for Password Authentication

Create the file `acl.txt` and place the username and password of each person you want to allow in the format `username:password`.

Add one set of credentials per line. Then place the file in the S3 bucket with the rest of the files.

Create a `.env` file in the root of the app with the following contents:

```
RACK_ENV=development
S3SERVER_SECRET_KEY=your_own_made_up_secret_key_for_cookies
S3_BUCKET=your_bucket
S3_ID=your_app_id
S3_KEY=your_key
S3_LINK_TIMEOUT=5
S3_REGION=us-west-2
```

Run the app with `foreman start` to test it out.

### Configuring for Google Authentication

Google authentication involves using only email addresses in the `acl.txt` file, and supplying two additional environment variables.

Create the file `acl.txt` and place the emails of the people you want to allow. Add one email per line. Then place the file in the S3 bucket with the rest of the files.

Register a new app with Google. Set up the credentials and make sure the callback URL points to `yourdomain.com/auth/google_oauth2/callback`.

Add the Google+ API to this new app so the app can grab the data from Google.

Create a `.env` file in the root of the app with the following contents:

```
RACK_ENV=development
S3SERVER_SECRET_KEY=your_own_made_up_secret_key_for_cookies
GOOGLE_ID=your_app_id
GOOGLE_SECRET=your_google_secret
S3_BUCKET=your_bucket
S3_ID=your_app_id
S3_KEY=your_key
S3_LINK_TIMEOUT=5
S3_REGION=us-west-2
```

This file should **never be checked in to version control.**

Run the app with `foreman start` to test it out.


## Production

In production, create a `.env` file on your server just like the one in development mode, but then change `RACK_ENV` to `production`.

Then run

```
foreman start
```

to start your app.

See the foreman documentation for [instructions on exporting to Systemd unit files or other startup services](https://github.com/ddollar/foreman/wiki/Exporting-for-production).

## Running with Docker

You may want to run this server in a container instead. There's a Dockerfile included in the repository.

Build the image:

```
docker build -t napcs/s3server .
```

Then run the container, passing it the environment variables you wish to use.

If using password authentication, run the container like this:

```
docker run -d -p 9292:9292 --name s3server \
-e RACK_ENV=production \
-e S3SERVER_SECRET_KEY=your_own_made_up_secret_key_for_cookies \
-e S3_BUCKET=your_bucket \
-e S3_ID=your_app_id \
-e S3_KEY=your_key \
-e S3_LINK_TIMEOUT=5 \
-e S3_REGION=us-west-2 \
napcs/s3server
```

If using Google authentication, run the container like this:

```
docker run -d -p 9292:9292 --name s3server \
-e RACK_ENV=production \
-e S3SERVER_SECRET_KEY=your_own_made_up_secret_key_for_cookies \
-e GOOGLE_ID=your_app_id \
-e GOOGLE_SECRET=your_google_secret \
-e S3_BUCKET=your_bucket \
-e S3_ID=your_app_id \
-e S3_KEY=your_key \
-e S3_LINK_TIMEOUT=5 \
-e S3_REGION=us-west-2 \
napcs/s3server
```


Stop the container with

```
docker stop s3server
```

Restart the container later with

```
docker start s3server
```

To clean everything up, remove the container with

```
docker rm s3server
```

and remove the image with

```
docker rmi napcs/s3server
```

## Changelog

* 2017-03-07
    * [Bugfix] Name of file was not displaying.
    * [Bugfix] US-West region was hardcoded in the ACL lookup.
    * [Feature] Added support for password logins with HTTP Basic Auth.
    * [Feature] Added HTML audio support for audio files.
* 2017-01-16 
    * Initial release with Google auth and Docker support.

## License

MIT. Copyright 2017 Brian P. Hogan.

