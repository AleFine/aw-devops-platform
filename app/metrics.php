<?php
header('Content-Type: text/plain');
$counterFile = '/tmp/requests_total';
if (!file_exists($counterFile)) {
    $count = 0;
} else {
    $raw = file_get_contents($counterFile);
    $count = (int)trim($raw);
}
$lastTsFile = '/tmp/last_request_ts';
$lastTs = file_exists($lastTsFile) ? (int)trim(file_get_contents($lastTsFile)) : 0;
echo "# HELP bootcamp_requests_total Total HTTP root requests served\n";
echo "# TYPE bootcamp_requests_total counter\n";
echo "bootcamp_requests_total {$count}\n";
echo "# HELP bootcamp_last_request_timestamp Unix timestamp of last root request\n";
echo "# TYPE bootcamp_last_request_timestamp gauge\n";
echo "bootcamp_last_request_timestamp {$lastTs}\n";
echo "# HELP bootcamp_scrape_timestamp Unix timestamp of this metrics scrape\n";
echo "# TYPE bootcamp_scrape_timestamp gauge\n";
echo "bootcamp_scrape_timestamp " . time() . "\n";
