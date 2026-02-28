import yaml
import os

with open('.github/workflows/ci.yml', 'r') as f:
    config = yaml.safe_load(f)

notification_step_success = {
    'name': 'Send Telegram Notification (Success)',
    'if': 'success()',
    'env': {
        'TELEGRAM_BOT_TOKEN': '${{ secrets.TELEGRAM_BOT_TOKEN }}',
        'TELEGRAM_CHAT_ID': '${{ secrets.TELEGRAM_CHAT_ID }}'
    },
    'run': './scripts/send-telegram.sh "✅ <b>CI Passed</b>\n\n<b>Repo:</b> ${{ github.repository }}\n<b>Branch:</b> ${{ github.ref_name }}\n<b>Commit:</b> ${{ github.sha }}"'
}

notification_step_failure = {
    'name': 'Send Telegram Notification (Failure)',
    'if': 'failure()',
    'env': {
        'TELEGRAM_BOT_TOKEN': '${{ secrets.TELEGRAM_BOT_TOKEN }}',
        'TELEGRAM_CHAT_ID': '${{ secrets.TELEGRAM_CHAT_ID }}'
    },
    'run': './scripts/send-telegram.sh "❌ <b>CI Failed</b>\n\n<b>Repo:</b> ${{ github.repository }}\n<b>Branch:</b> ${{ github.ref_name }}\n<b>Commit:</b> ${{ github.sha }}"'
}

for job_name in config['jobs']:
    steps = config['jobs'][job_name]['steps']
    steps.append(notification_step_success)
    steps.append(notification_step_failure)

with open('.github/workflows/ci.yml', 'w') as f:
    yaml.dump(config, f, sort_keys=False)
