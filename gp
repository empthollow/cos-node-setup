#!/bin/bash
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
	read -p "comment> " comment
	git add . && git commit -m "$comment" && git push origin main
else
	echo "authentication failed"
fi
