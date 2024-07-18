# README

This is a simple Rails 7.1 application built based on Rails "blog app" guide.
We will be using this app to learn how to deploy a Rails app to VPS with Kamal.

Sources:
- [Rails Guides](https://guides.rubyonrails.org/getting_started.html#creating-the-blog-application)
- [Kamal](https://kamal-deploy.org/)

Pre-requisites:
- Ruby 3.3.4
- installed and configured git
- installed and configured ssh
- ssh-key without passphrase
- docker installed and updated

# Workshop instructions

## 1. Sign up to the Companion app at kamal.cklos.foo

## 2 Clone the blog-space and install Kamal

```
git clone git@github.com:visualitypl/kamal-workshops-app.git
git clone https://github.com/visualitypl/kamal-workshops-app.git

gem install kamal
```

## 3 First deployment

Example files for this task:
- [deploy.yml.example-1](config/deploy.yml.example-1)
- [.env.example-1](.env.example-1)

### 3.1 Add kamal to blog-space
```
kamal init blog-space
```

### 3.2 Setup deploy.yml

We will need to edit:

- service (name of the app: blog-space)
- image (#{Docker Hub username from the companion app}/#{name of the app})
- servers (IP from the companion app)
- registry (username: #{Docker Hub username from the companion app})
- env (clear, secret)
- builder (remote: [arch: amd64, host: #{from the companion app}])

### 3.3 Setup .env

We will need to edit:

- KAMAL_REGISTRY_PASSWORD (Docker Hub token from the companion app)
- SECRET_KEY_BASE (generate secret key base with `rails secret`)
- POSTGRES_PASSWORD (pick a password)
- REDIS_PASSWORD (pick a password)
- REDIS_URL (`"redis://:<REDIS_PASSWORD>@blog-space-redis:6379/0"`, substitute the password)

### 3.4 Setup docker-setup kamal hook

We will need to rename docker-setup.sample to docker-setup
in .kamal/hooks/ directory

### 3.5 Deploy

To prepare docker on hosts, push env, deploy postgres accessory and deploy the app we need to run:

```shell
kamal server bootstrap
kamal env push
kamal accessory boot postgres
kamal deploy
```

Alternatively, you can run command that calls all the above:

```shell
kamal setup
```

### 3.6 Check the result

To check the result, run:

```shell
kamal audit
kamal details
```

Visit the app at http://#{IP}
