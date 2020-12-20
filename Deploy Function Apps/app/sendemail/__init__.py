import smtplib
import os
import sys

import azure.functions as func


def main(req: func.HttpRequest) -> func.HttpResponse:
    headers = {"my-http-header": "some-value"}


    req_body = req.get_json()
    params = req.params

    msg = req_body
    email_pass = os.getenv('mail_pass_sec')

    receive_list = ['kainvey@gmail.com', 'kain.wei@westpac.co.nz', 'jack.shan@servian.com']

    message = 'From: kain \nTo: {}\nSubject: send email from python\n\n{}'
    receive_list_txt = ", ".join(receive_list)

    mailserver = smtplib.SMTP('smtp.office365.com', 587)
    mailserver.ehlo()
    mailserver.starttls()
    mailserver.login('kain.wei@enterpriseit.co.nz', email_pass)
    mailserver.sendmail('kain.wei@enterpriseit.co.nz', receive_list,
                        message.format(receive_list_txt, ' Send an email from python body ' +
                                                         'message is : {}, head msg is : {}'.format(msg, params)))
    mailserver.quit()

    if msg:
        return func.HttpResponse(f"Hello {msg}!", headers=headers)
    else:
        return func.HttpResponse(
             "Please pass a name on the query string or in the request body",
             headers=headers, status_code=400
        )



