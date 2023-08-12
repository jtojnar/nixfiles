<?php

if (isset($_POST['password'])) {
    try {
        // Undefined | Multiple files | $_FILES corruption attack.
        if (
            !isset($_FILES['file']['error']) ||
            is_array($_FILES['file']['error'])
        ) {
            throw new RuntimeException('Invalid parameters.');
        }

        // Check upload error.
        match ($_FILES['file']['error']) {
            UPLOAD_ERR_OK => null,
            UPLOAD_ERR_NO_FILE => throw new RuntimeException('No file sent.'),
            UPLOAD_ERR_INI_SIZE, UPLOAD_ERR_FORM_SIZE => throw new RuntimeException('Exceeded filesize limit.'),
            default => throw new RuntimeException('Unknown errors.'),
        };

        // Limit file size.
        if ($_FILES['file']['size'] > 30_000_000) {
            throw new RuntimeException('Exceeded filesize limit.');
        }

        // Check MIME type.
        $finfo = new finfo(FILEINFO_MIME_TYPE);
        if ($finfo->file($_FILES['file']['tmp_name']) !== 'application/pdf') {
            throw new RuntimeException('Invalid file format.');
        }

        $originalName = $_FILES['file']['name'];
        $tempFile = tempnam(sys_get_temp_dir(), $originalName);

        $args = [
            '@qpdf@',
            '--decrypt',
            '--password=' . escapeshellarg($_POST['password']),
            escapeshellarg($_FILES['file']['tmp_name']),
            escapeshellarg($tempFile),
        ];
        exec(implode(' ', $args) . ' 2>&1', $output, $resultCode);

        if ($resultCode !== 0) {
            throw new RuntimeException(implode(PHP_EOL, $output));
        }

        header('Content-Disposition: attachment; filename="' . urlencode($originalName) . '"');
        header('Content-Type: application/pdf; charset=utf-8');
        echo file_get_contents($tempFile);
        die;
    } catch (RuntimeException $e) {
        header('Content-Type: text/plain; charset=utf-8');
        echo $e->getMessage();
        die;
    } finally {
        if (isset($tempFile)) {
            unlink($tempFile);
        }
    }
}
?>
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PDF Password remover</title>
</head>
<body>
<h1>PDF Password remover</h1>

<form action="" method="post" enctype="multipart/form-data">
<p><label>File: <input type="file" name="file" required></label></p>
<p><label>Password: <input type="text" name="password" required></label></p>
<button type="submit">Remove password</button>
</form>
</body>
</html>
