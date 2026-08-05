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
    msg["Subject"] = f"Your Job Scraper Report - {date_str}"
    # Setting the From header to look like it came from agent@scrappyjob.com
    msg["From"] = "ScrappyJob Agent <agent@scrappyjob.com>"
    msg["To"] = target_email
    total_jobs = len(jobs)
    top_jobs_html = ""
    for job in jobs[:5]:
        link = job.get("Application Link", "#")
        top_jobs_html += f'''
        <tr>
            <td style="padding: 12px; border-bottom: 1px solid #e0e0e0; font-weight: bold; color: #333;">{job.get('Job Title')}</td>
            <td style="padding: 12px; border-bottom: 1px solid #e0e0e0; color: #555;">{job.get('Company')}</td>
            <td style="padding: 12px; border-bottom: 1px solid #e0e0e0; color: #777;">{job.get('Location')}</td>
            <td style="padding: 12px; border-bottom: 1px solid #e0e0e0;">
                <a href="{link}" style="background-color: #0044cc; color: #ffffff; padding: 6px 12px; text-decoration: none; border-radius: 4px; font-size: 12px; font-weight: bold;">Apply</a>
            </td>
        </tr>
        '''
    html_content = f'''
    <html>
      <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; background-color: #f4f7f6; padding: 20px;">
        <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.05);">
            <div style="background-color: #002060; padding: 24px; text-align: center;">
                <h1 style="color: #ffffff; margin: 0; font-size: 24px;">ScrappyJob Alert</h1>
            </div>
            <div style="padding: 24px;">
                <p style="font-size: 16px; margin-top: 0;">Hello,</p>
                <p style="font-size: 16px;">Your automated job scrape for <strong>{date_str}</strong> has successfully completed.</p>
                
                <div style="background-color: #e8f0fe; padding: 16px; border-radius: 8px; margin: 24px 0; text-align: center;">
                    <span style="font-size: 14px; color: #1a73e8; text-transform: uppercase; font-weight: bold;">Total Jobs Discovered</span><br>
                    <span style="font-size: 32px; color: #002060; font-weight: bold;">{total_jobs}</span>
                </div>

                <h3 style="color: #002060; border-bottom: 2px solid #f0f0f0; padding-bottom: 8px;">Top 5 Job Highlights</h3>
                <table style="border-collapse: collapse; width: 100%; margin-bottom: 24px;">
                  <thead>
                    <tr>
                      <th style="padding: 12px; border-bottom: 2px solid #002060; text-align: left; color: #002060; font-size: 14px;">Title</th>
                      <th style="padding: 12px; border-bottom: 2px solid #002060; text-align: left; color: #002060; font-size: 14px;">Company</th>
                      <th style="padding: 12px; border-bottom: 2px solid #002060; text-align: left; color: #002060; font-size: 14px;">Location</th>
                      <th style="padding: 12px; border-bottom: 2px solid #002060; text-align: left; color: #002060; font-size: 14px;">Action</th>
                    </tr>
                  </thead>
                  <tbody>
                    {top_jobs_html}
                  </tbody>
                </table>
                <p style="font-size: 14px; color: #666;">For the complete list, including posting times and extra notes, please check the attached Excel spreadsheet.</p>
            </div>
            <div style="background-color: #f8f9fa; padding: 16px; text-align: center; border-top: 1px solid #e0e0e0;">
                <p style="font-size: 12px; color: #999; margin: 0;">Delivered by the <strong>ScrappyJob Bot</strong></p>
            </div>
        </div>
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
