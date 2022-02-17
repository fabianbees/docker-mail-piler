<?php

$config['SITE_NAME'] = 'HOSTNAME';
$config['SITE_URL'] = 'http://' . $config['SITE_NAME'] . '/';
$config['DIR_BASE'] = '/var/piler/www/';

$config['SMTP_DOMAIN'] = $config['SITE_NAME'];
$config['SMTP_FROMADDR'] = 'no-reply@' . $config['SITE_NAME'];
$config['ADMIN_EMAIL'] = 'admin@' . $config['SITE_NAME'];

$config['DB_DRIVER'] = 'mysql';
$config['DB_HOSTNAME'] = '';
$config['DB_USERNAME'] = '';
$config['DB_PASSWORD'] = '';
$config['DB_DATABASE'] = '';

$config['SMARTHOST'] = '';
$config['SMARTHOST_PORT'] = 25;