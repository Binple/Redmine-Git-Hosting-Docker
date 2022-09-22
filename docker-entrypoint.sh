#!/bin/bash

# gitolite setting
if [ ! -d /var/lib/git/.gitolite ]; then
	chown git:git /var/lib/git
	su-exec git gitolite setup -pk /opt/ssh_keys/redmine_gitolite_admin_id_rsa.pub
	su-exec git sed -i -e "s/GIT_CONFIG_KEYS.*/GIT_CONFIG_KEYS  =>  '.*',/g" /var/lib/git/.gitolite.rc
	su-exec git sed -i -e "s/# LOCAL_CODE.*=>.*\"\$ENV{HOME}\/local\"/LOCAL_CODE => \"\$ENV{HOME}\/local\"/" /var/lib/git/.gitolite.rc
	chmod go-w /var/lib/git
	passwd -d git
fi

echo "production:" > /opt/redmine/config/database.yml
echo "  adapter: postgresql" >> /opt/redmine/config/database.yml
echo "  host: $DB_HOST" >> /opt/redmine/config/database.yml
echo "  port: $DB_PORT" >> /opt/redmine/config/database.yml
echo "  database: $DB_NAME" >> /opt/redmine/config/database.yml
echo "  username: $DB_USER" >> /opt/redmine/config/database.yml
echo "  password: \"$DB_PASS\"" >> /opt/redmine/config/database.yml
echo "  encoding: utf8" >> /opt/redmine/config/database.yml

bundle check || bundle install

if [ ! -s /opt/redmine/config/secrets.yml ]; then
	if [ ! -f /opt/redmine/config/initializers/secret_token.rb ]; then
		rake generate_secret_token
	fi
fi

rake db:migrate
rake redmine:plugins:migrate

# remove PID file to enable restarting the container
rm -f /opt/redmine/tmp/pids/server.pid

exec "$@"