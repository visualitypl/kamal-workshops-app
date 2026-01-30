# README

This is a simple Rails 7.1 application built based on Rails "blog app" guide.
We will be using this app to learn how to deploy a Rails app to VPS with Kamal.

Sources:
- [Rails Guides](https://guides.rubyonrails.org/getting_started.html#creating-the-blog-application)
- [Kamal](https://kamal-deploy.org/)

Pre-requisites:
- Ruby 3.4.8
- installed and configured git
- installed and configured ssh
- ssh-key without passphrase
- docker installed and updated

# Workshop instructions

## TASK 1—Sign up to the Companion app
1. Find or create an SSH key without a passphrase

   https://linuxize.com/post/how-to-setup-passwordless-ssh-login/#setup-ssh-passwordless-login

2. Go to `kamal.cklos.foo`
3. Click on `Sign up` button
4. Enter signup code form slides, username, password, **PUBLIC** part of SSH key
5. Test your SSH connection to assigned servers

## TASK 2—Create a new Rails 8 app and deploy it with Kamal

1. Generate a new application
    ```
    gem update rails
    rails _8.0.1_ new kamal-workshops-new
    ```

2. Add Posts scaffold (optional)
    ```
    bin/rails generate scaffold Posts title:string 
    bin/rails db:migrate
    ```
    set `root "posts#index"` in `config/routes.rb`

3. Edit `config/deploy.yml`
    ```
    image: <docker_username- e.g. kamal_gh_1>/kamal_workshops_new
    
    servers:
      web:
        - <IP address - e.g. 255.255.255.100>
   
    proxy:
      ssl: true
      host: <Host - e.g pluto.cklos.foo>
    
    registry:
      username: <docker_username - e.g. kamal_gh_1>
    ```

4. Set KAMAL_REGISTRY_PASSWORD environment variable in terminal
    ```
    export KAMAL_REGISTRY_PASSWORD=<docker_token>
    ```
   
5. Commit changes
6. Deploy with `kamal setup`
7. Go to `pluto.cklos.foo`

   You have deployed your application.

## Task 3—Migrate Rails 7 app to Kamal deployment

### 0 Clone the repository
```
git clone git@github.com:visualitypl/kamal-workshops-app.git
git clone https://github.com/visualitypl/kamal-workshops-app.git
```

Example files for this task:
- [deploy.yml.example](config/deploy.yml.example)
- [.secrets.example](.secrets.example)

### 1 Add kamal to Gemfile
```
gem "kamal", require: false
```

### 2 initialize kamal
```
bundle install
kamal init
```

### 3 Setup deploy.yml

We will need to set:

- service (name of the app: blog-space)
- image (#{Docker Hub username from the companion app}/#{name of the app})
- servers (IP from the companion app)
- proxy (hostname)
- registry (username: #{Docker Hub username from the companion app})
- env (clear, secret)
- accessories

### 4 Setup .kamal/secrets

We will need to edit:

- KAMAL_REGISTRY_PASSWORD (Docker Hub token from the companion app)
- SECRET_KEY_BASE (generate secret key base with `rails secret`)
- POSTGRES_PASSWORD (pick any password)
- REDIS_PASSWORD (pick any password)
- REDIS_URL (substitute password in string: "redis://:$REDIS_PASSWORD@blog-space-redis:6379/0")

### 5 Deploy

To install docker, start postgres and redis containers, kamal-proxy and deploy the app we need to run:

```shell
kamal server bootstrap
kamal env push
kamal accessory boot postgres && kamal accessory boot redis 
# or kamal accessory boot all
kamal deploy
```

Alternatively, you can run a command that calls all the above:

```shell
kamal setup
```

### 6 Check the result

To check the result, run:

```shell
kamal audit
kamal details
```

Visit the app at hostname you set in the proxy.

## Task 4-Deploy staging destination

Example files for this task:
- [deploy.staging.yml.example](config/deploy.staging.yml.example)
- [.secrets.example](.secrets.example)

### 1 Add config for staging destination

Create `config/deploy.staging.yml`.
We only need to override values from `config/deploy.yml` that are different for staging.

```yaml
servers:
  web:
    hosts:
      - 209.38.199.143

  worker:
    hosts:
      - 209.38.199.143

proxy:
   host: bear.8301738.xyz

env:
  clear:
    RAILS_ENV: "staging"
    POSTGRES_DB: "blog_space_staging"

accessories:
   postgres:
      host: 209.38.199.143

   redis:
      host: 209.38.199.143
      cmd: "redis-server --requirepass <%= File.read('.kamal/secrets.staging')[/REDIS_PASSWORD="(.*?)"/, 1] %>"
```

### 2 Add secrets for staging destination

Create `.kamal/secrets.staging` and add:

- KAMAL_REGISTRY_PASSWORD (Docker Hub token from the companion app)
- SECRET_KEY_BASE (generate secret key base with `rails secret`)
- POSTGRES_PASSWORD (pick any password)
- REDIS_PASSWORD (pick any password)
- REDIS_URL (substitute password in string: "redis://:$REDIS_PASSWORD@blog-space-redis:6379/0")

### 3 Deploy

To use kamal with staging destination, we need to pass `-d staging` flag to all commands.
Like before, we need to set up docker on hosts, deploy postgres and redis accessories and deploy the app.

```shell
kamal setup -d staging
```

```shell
kamal server bootstrap -d staging
kamal env push -d staging
kamal accessory boot all -d staging
kamal deploy -d staging
```

### 4 Check the result

To check the result, run:

```shell
kamal audit -d staging
kamal details -d staging
```

Visit the app.

## Task 5-Breaking and fixing

### 1 Breaking

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

### 2 Breaking even more

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

### 3 The Rollback

Rollback to a previous version of the app:

```shell
# to find the version run:
kamal audit

kamal rollback <VERSION>
```

### 4 Cleanup

Remove the migration that we added previously.

This task has no solution here ;)
