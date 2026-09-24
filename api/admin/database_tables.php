<?php
require_once 'config.php';
requireLogin();
$table = $_GET['table'] ?? 'religions';
header('Location: manage_table.php?table=' . urlencode($table));
exit;
