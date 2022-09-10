# S3Server

Simple file server providing restricted access to an S3 bucket's files.  Displays files and provides download links for each file that expire.

## How it works

When a user visits the app, they are redirected to log in, either with their Google account, or a username and password, depending on the configuration. 

If the app is configured to use Google logins, then, once logged in, the application looks for a file in the S3 bucket called `acl.txt` for the email of the logged in user. If their email exists in the file, they get in. 

If using passwords, the server checks the `acl.txt` file in the bucket for the credentials passed in by the user.

The ACL file eliminates the requirement for a database and makes sharing a bucket of files simple.

## Limitations

Currently, this server only handles a single bucket's contents up to 1000 elements, and cannot support "folders" within a bucket since those aren't really things anyway. This is designed to share a specific set of resources quickly.

## Requirements

1. An S3 bucket or a compatible service like DigitalOcean Spaces (See the section later in this README for configuring Spaces.
2. (Optional) A Google account with the ability to create an application.

## Configuration

You can use password authentication or Google authentication to allow access to your bucket.

In both cases, first identify the bucket and region you want to use. Ensure you have the ID and access key for the bucket before proceeding.

The server launches on port `9292` by default. You can override this.

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
S3SERVER_LOGIN=password
S3SERVER_PORT=9292
S3SERVER_HIDE_FOLDERS=true
```

This file should **never be checked in to version control.**

Here's what the options do:

* `RACK_ENV` is `development` or `production`
* `S3SERVER_SECRET_KEY` is some key you make yourself to use in securing the links.
* `S3_BUCKET` is your bucket.
* `S3_ID` is your AWS ID
* `S3_KEY` is your AWS secret key
* `S3_LINK_TIMEOUT` is how long in minutes the generated URLs are good for.
* `S3_REGION` is the region for the bucket. Make sure this is correct.
* `S3SERVER_LOGIN` is the login type. Can be `password`, `google`, or `none`
* `S3SERVER_PORT` is the port this runs on.
* `S3SERVER_HIDE_FOLDERS` (optional) lets you tell S3Server to only show the objects in the top level of the bucket. If this is not set, all files in all subfolders will appear on one page.

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
S3_BUCKET=your_bucket
S3_ID=your_app_id
S3_KEY=your_key
S3_LINK_TIMEOUT=5
S3_REGION=us-west-2
S3SERVER_LOGIN=google
GOOGLE_ID=your_app_id
GOOGLE_SECRET=your_google_secret
S3SERVER_PORT=9292
S3SERVER_HIDE_FOLDERS=true
```

This file should **never be checked in to version control.**

Run the app with `foreman start` to test it out.

## Anonymous access

So you want anyone anywhere to be able to grab files from your bucket?

Are you crazy?

Okay, this is supported, but dangerous. You're opening an S3 bucket to the entire world. You're gonna pay pretty high rates for all that data transfer. The links will still expire after your specified timeout, but literally EVERYONE can see everything in your bucket.

Create a `.env` file in the root of the app with the following contents:

```
RACK_ENV=development
S3SERVER_SECRET_KEY=your_own_made_up_secret_key_for_cookies
S3_BUCKET=your_bucket
S3_ID=your_app_id
S3_KEY=your_key
S3_LINK_TIMEOUT=5
S3_REGION=us-west-2
S3SERVER_LOGIN=none
S3SERVER_PORT=9292
S3SERVER_HIDE_FOLDERS=true
```

That's it. Fire it up with `foreman start` to test things out.

## Production

In production, create a `.env` file on your server just like the one in development mode, but then change `RACK_ENV` to `production`.

Then run

```
foreman start
```

to start your app.

See the foreman documentation for [instructions on exporting to Systemd unit files or other startup services](https://github.com/ddollar/foreman/wiki/Exporting-for-production).

Probably should put this behind Nginx with a Let's Encrypt certificate too.

## Running with Docker

You may want to run this server in a container instead. There's a Dockerfile included in the repository if you want to build your own image. Alternatively, you can get the pre-built image from Docker Hub.

```
docker pull napcs/s3server
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
-e S3SERVER_HIDE_FOLDERS=true \
-e S3SERVER_LOGIN=password \
-e S3SERVER_PORT=9292 \
napcs/s3server
```

If using Google authentication, run the container like this:

```
docker run -d -p 9292:9292 --name s3server \
-e RACK_ENV=production \
-e S3SERVER_SECRET_KEY=your_own_made_up_secret_key_for_cookies \
-e S3_BUCKET=your_bucket \
-e S3_ID=your_app_id \
-e S3_KEY=your_key \
-e S3_LINK_TIMEOUT=5 \
-e S3_REGION=us-west-2 \
-e S3SERVER_LOGIN=google \
-e S3SERVER_PORT=9292 \
-e S3SERVER_HIDE_FOLDERS=true \
-e GOOGLE_ID=your_app_id \
-e GOOGLE_SECRET=your_google_secret \
napcs/s3server
```

And if you just don't want any authentication for some reason:

```
docker run -d -p 9292:9292 --name s3server \
-e RACK_ENV=production \
-e S3SERVER_SECRET_KEY=your_own_made_up_secret_key_for_cookies \
-e S3_BUCKET=your_bucket \
-e S3_ID=your_app_id \
-e S3_KEY=your_key \
-e S3_LINK_TIMEOUT=5 \
-e S3_REGION=us-west-2 \
-e S3SERVER_LOGIN=none \
-e S3SERVER_PORT=9292 \
-e S3SERVER_HIDE_FOLDERS=true \
napcs/s3server
```

And you're good to go.


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

You can build your own image with

```
docker build -t s3server .
```

And just use that instead of the one from Docker Hub. 

## Support for DigitalOcean Spaces

[DigitalOcean Spaces](https://spaces.digitalocean.com) is DigitalOcean's object storage system. It's compatible with S3.

To use it with S3Server, specify the `S3_ENDPOINT` to `https://[region].digitaloceanspaces.com` where `[region]` is the region you're using.

The `S3_BUCKET` is the name of your Space.

For a bucket called `s3test` in the `nyc3` region, the environment variables look like this:

```
S3_ENDPOINT=https://nyc3.digitaloceanspaces.com
S3_REGION=nyc3
S3_BUCKET=s3test
S3_ID=your_spaces_key
S3_KEY=your_spaces_secret
S3_LINK_TIMEOUT=5
S3SERVER_LOGIN=password
S3SERVER_PORT=9292
```

Once the server is configured, start it and it'll use DigitalOcean Spaces as your backend.

## Nginx as a Reverse Proxy

You might not want to expose this to the web. And if you're gonna take passwords through it,, probably best to use HTTPS. 

Nginx is a nice quick way to pull this off. 

Get an Ubuntu 16.04 server. Install Nginx on it with 

```
sudo apt-get install nginx
```

Get yourself a domain name like `s3server.example.com` and point it at your box's IP address.

Use this configuration to set up a reverse proxy with Nginx. Put it in `/etc/nginx/sites-available/s3server.conf`:

```
server {
    listen 80;
    listen [::]:80;
    server_name s3server.example.com;

		location / {
			proxy_pass http://localhost:9292;
			include /etc/nginx/proxy_params;
		}
}
``` 

Symlink it:

```
sudo ln -nfs /etc/nginx/sites-available/s3server.conf /etc/nginx/sites-enabled/s3server.conf
```

Then use Certbot to get a Let's Encrypt certificate for this and redirect all traffic from HTTP to HTTPS. Visit `https://s3server.example.com` and you're golden.

## Changelog
* 2022-09-09 (0.6.3)
  * Add option to hide folders and only show the top folder of a bucket. 
* 2021-09-12 (0.6.2)
  * Directories are no longer shown in the UI. Only the actual files are displayed, but their paths are still shown.
  * Updated AWS dependency to use the AWS SDK
  * Docker image uses Alpine, reducing the size of the image.

* 2019-10-16 (0.5.1)
  * better mobile UI when filenames are long
* 2018-02-18 (0.5.0)
    * UI changes. Now shows file sizes.
    * Minor refactoring under the hood.
* 2018-01-23 (0.4.1)
    * Added support for port
    * Pushed image to Docker Hub

* 2018-01-22 (0.4)
    * Add support to override the endpoint in order to support DigitalOcean Spaces
    * Tested with DigitalOcean Spaces
    * Better support for unknown file types on the show page
    * Fix broken image in header when using password logins
    * Displays version in footer

* 2017-08-27 (0.3)
    * Breaking change:
      * To handle Google logins, you'll need to add the new `S3SERVER_LOGIN` variable. Set it to `google`, `password`, or `none` depending on the scheme.
    * [Feature] Add support for serving buckets without a password. Use at your own risk.
    * Reworked login logic
    * CSS tweaks to make audio player 100% wide
    * CSS tweak for large screens

* 2017-03-07 (0.2)
    * [Bugfix] Name of file was not displaying.
    * [Bugfix] US-West region was hardcoded in the ACL lookup.
    * [Feature] Added support for password logins with HTTP Basic Auth.
    * [Feature] Added HTML audio support for audio files.

* 2017-01-16 (0.1)
    * Initial release with Google auth and Docker support.

## License

MIT. Copyright 2017 Brian P. Hogan.

