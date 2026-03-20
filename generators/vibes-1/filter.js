const line = process.argv[2];

// Skip strings where symbols are flanked by digits on both sides (e.g. "3!@#4")
if (/\d[^a-zA-Z0-9]+\d/.test(line)) {
    process.exit(1);
}

process.exit(0);
