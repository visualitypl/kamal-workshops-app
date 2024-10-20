# README

This is a simple Rails 7.1 application built based on Rails "blog app" guide.
We will be using this app to learn how to deploy a Rails app to VPS with Kamal.

Sources:
- [Rails Guides](https://guides.rubyonrails.org/getting_started.html#creating-the-blog-application)
- [Kamal](https://kamal-deploy.org/)

Pre-requisites:
- Ruby 3.3.5
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

## 3 Task 1 - Application with postgres

Example files for this task:
- [deploy.yml.example-1](config/deploy.yml.example-1)
- [.env.example-1](.env.example-1)

### 3.1 Add kamal to blog-space
```
kamal init
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

## 4 Task 2 - Adding redis and sidekiq

Example files for this task:
- [deploy.yml.example-2](config/deploy.yml.example-2)
- [.env.example-2](.env.example-2)

### 4.1 Add sidekiq to deploy.yml

Add "worker" role to servers (save IP as web)

```yaml
servers:
  worker:  
    hosts:  
      - 255.255.255.100 ## CHANGE ME 
    cmd: bundle exec sidekiq  
    options:  
      network: "kamal"
```

### 4.2 Set Sidekiq as ActiveJob backend

We will need to edit `config/environments/production.rb` and `config/environments/staging.rb`

```ruby
config.active_job.queue_adapter = :sidekiq
```

### 4.3 Add redis to deploy.yml

Add "redis" accessory

```yaml
accessories:
  redis:
    image: "redis:7.2-alpine"
    roles:
      - web
    directories:
      - data:/data
    options:
      network: "kamal"
    cmd: "redis-server --requirepass <%= File.read('.env')[/REDIS_PASSWORD="(.*?)"/, 1] %>"  
```

### 4.4 Add Redis env vars to .env

Add two env vars to `.env`:

- REDIS_PASSWORD (pick a password)
- REDIS_URL (`"redis://:<REDIS_PASSWORD>@blog-space-redis:6379/0"`, substitute the password with above)

### 4.5 Reference REDIS_URL in deploy.yml

Add `REDIS_URL` to `env` section of deploy.yml

```yaml
env:
  secret:
    - SECRET_KEY_BASE
    - POSTGRES_PASSWORD
    - REDIS_URL
```

### 4.6 Use Redis as ActiveCable backend

Edit `config/cable.yml` and set `adapter: redis` on production and staging

```yaml
staging:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL", "") %>
  channel_prefix: blog_space_production

production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL", "") %>
  channel_prefix: blog_space_production
```
### 4.7 Commit the changes

```shell
git add -A
git commit -m "Add redis and sidekiq"
```

### 4.8 Push env vars to the server

```shell
kamal env push
```

### 4.9 Start redis accessory and deploy the app

```shell
kamal accessory boot redis
kamal deploy
```

### 4.10 Check the result

To check the result, run:

```shell
kamal audit
kamal details
```

Visit the app at http://#{IP}

## 5. Deploy staging destination

Example files for this task:
- [deploy.staging.yml.example](config/deploy.staging.yml.example)
- [.env.staging.example](.env.staging.example)

### 5.1 Add config for staging destination

Create `config/deploy.staging.yml`.
We only need to override values from `config/deploy.yml` that are different for staging.

```yaml
servers:
  web:
    hosts:
      - [HOST IP] ## CHANGE ME

  worker:
    hosts:
      - [HOST IP] ## CHANGE ME

env:
  clear:
    RAILS_ENV: "staging"
    POSTGRES_DB: "blog_space_staging"

accessories:
  postgres:
    files:
      - "config/init.staging.sql:/docker-entrypoint-initdb.d/init.sql"

  redis:
    cmd: "redis-server --requirepass <%= File.read('.env.staging')[/REDIS_PASSWORD="(.*?)"/, 1] %>"
```

### 5.2 Add env vars for staging destination

Create `.env.staging` and add:

- SECRET_KEY_BASE (generate secret key base with `rails secret`)
- POSTGRES_PASSWORD (pick a password)
- REDIS_PASSWORD (pick a password)
- REDIS_URL (`"redis://:<REDIS_PASSWORD>@blog-space-redis:6379/0"`, substitute the password with above)

Notice that we are not setting `KAMAL_REGISTRY_PASSWORD` env var, because we are using the same one as in production.

### 5.3 Deploy

To use kamal with staging destination we need to pass `-d staging` flag to all commands.
Like before we need to setup docker on hosts, push env, deploy postgres accessory and deploy the app.

```shell
kamal setup -d staging
```

```shell
kamal server bootstrap -d staging
kamal env push -d staging
kamal accessory boot all -d staging
kamal deploy -d staging
```

### 5.4 Check the result

To check the result, run:

```shell
kamal audit -d staging
kamal details -d staging
```

Visit the app at http://#{STAGING-IP}

## 6. Breaking and fixing

### 6.1 Breaking

We will break the app by generating a migration that will fail.

```shell
bundle exec rails generate migration addAuthorToArticle
```

```ruby
class AddAuthorToArticle < ActiveRecord::Migration[7.1]
  def change
    add_column :articles, :author, :string, null: false
  end
end
```

Commit the changes and push them to the server.

```shell
git add -A
git commit -m "Add author to article"
kamal deploy
```

Inspect the output of the deploy command and notice that
the app have not been deployed to the server.

### 6.2 Breaking even more

Fix the migration by adding a default value to the author column.
BUT at the same time break something else.

```ruby
class AddAuthorToArticle < ActiveRecord::Migration[7.1]
  def change
    add_column :articles, :author, :string, null: false, default: ""
  end
end
```

Comment the "delete_barons_comments" route in `config/routes.rb`

```ruby
# post "delete_barons_comments", on: :member
```

Commit the changes and push them to the server.

This time the migration were applied to the database.
But "the core functionality" of the app is lost.

### 6.3 The Rollback

Rollback to previous version of the app:

```shell
kamal rollback <VERSION>

# to find the version run:
kamal audit
```

### 6.4 Cleanup

Remove the migration that we added previously.

This task has no solution here ;)
