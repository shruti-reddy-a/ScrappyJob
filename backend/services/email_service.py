import os
import smtplib
from email.message import EmailMessage
from typing import List, Dict, Any

def send_email(target_email: str, jobs: List[Dict[str, Any]], filename: str, date_str: str):
    smtp_server = "smtp.gmail.com"
    smtp_port = 587
    smtp_username = os.getenv("SMTP_USERNAME")
    smtp_password = os.getenv("SMTP_PASSWORD")
    if not smtp_username or not smtp_password:
        print("SMTP credentials missing, skipping email.")
        return False
    msg = EmailMessage()
    msg["Subject"] = f"Job Scraper Report - {date_str}"
    msg["From"] = smtp_username
    msg["To"] = target_email
    total_jobs = len(jobs)
    top_jobs_html = ""
    for job in jobs[:5]:
        link = job.get("Application Link", "#")
        top_jobs_html += f'''
        <tr>
            <td style="padding: 8px; border: 1px solid #ddd;">{job.get('Job Title')}</td>
            <td style="padding: 8px; border: 1px solid #ddd;">{job.get('Company')}</td>
            <td style="padding: 8px; border: 1px solid #ddd;">{job.get('Location')}</td>
            <td style="padding: 8px; border: 1px solid #ddd;"><a href="{link}">Apply</a></td>
        </tr>
        '''
    html_content = f'''
    <html>
      <body style="font-family: Arial, sans-serif; line-height: 1.6;">
        <h2>Automated Job Scraper Report</h2>
        <p>Your scheduled job scrape for <strong>{date_str}</strong> is complete.</p>
        <p><strong>Total Jobs Found:</strong> {total_jobs}</p>
        <h3>Top 5 Job Highlights</h3>
        <table style="border-collapse: collapse; width: 100%; max-width: 600px;">
          <thead>
            <tr style="background-color: #002060; color: white;">
              <th style="padding: 8px; border: 1px solid #ddd; text-align: left;">Title</th>
              <th style="padding: 8px; border: 1px solid #ddd; text-align: left;">Company</th>
              <th style="padding: 8px; border: 1px solid #ddd; text-align: left;">Location</th>
              <th style="padding: 8px; border: 1px solid #ddd; text-align: left;">Link</th>
            </tr>
          </thead>
          <tbody>
            {top_jobs_html}
          </tbody>
        </table>
        <p>Please find the complete list of jobs attached as an Excel spreadsheet.</p>
        <p>Best regards,<br>ScrappyJob Bot</p>
      </body>
    </html>
    '''
    msg.add_alternative(html_content, subtype='html')
    if os.path.exists(filename):
        with open(filename, 'rb') as f:
            excel_data = f.read()
            msg.add_attachment(excel_data, maintype='application', subtype='vnd.openxmlformats-officedocument.spreadsheetml.sheet', filename=os.path.basename(filename))
    try:
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()
            server.login(smtp_username, smtp_password)
            server.send_message(msg)
        return True
    except Exception as e:
        print(f"Failed to send email: {e}")
        return False
