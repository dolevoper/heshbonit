import * as logger from "firebase-functions/logger";
import * as functions from "firebase-functions";
import {initializeApp, applicationDefault} from "firebase-admin/app";
import {getStorage} from "firebase-admin/storage";
import * as puppeteer from "puppeteer";

initializeApp({
  credential: applicationDefault(),
});

export const createInvoice =
  functions
      .runWith({memory: "1GB"})
      .firestore
      .document("invoices/{id}")
      .onCreate(async (snap) => {
        try {
          logger.info("starting invoice creation", snap.id);

          const data = snap.data();
          const file = getStorage()
              .bucket("heshbonit-invoices")
              .file(`${snap.id}.pdf`);

          const browser = await puppeteer.launch();
          const page = await browser.newPage();
          /* eslint-disable max-len */
          const html = `
<html dir="rtl">
  <head>
    <title>חשובנית ${snap.id}</title>
  </head>
  <body>
    <h1>אדווה דולב</h1>
    <h2>עוסק פטור 201637691</h2>
    <h3>קבלה מס' ${snap.id}</h3>
    <time datetime="${data.date}">${data.date.split("-").reverse().join("/")}</time>
    <p>
      <h4>עבור</h4>
      ${data.description}
    </p>
    <p>סה"כ: ${data.amount}</p>
  </body>
</html>`;
          /* eslint-enable max-len */

          await page.setContent(html, {waitUntil: "networkidle2"});
          await page.emulateMediaType("screen");

          const pdf = await page.pdf({
            format: "A4",
          });

          await file.save(pdf, {contentType: "application/pdf"});

          await browser.close();

          logger.info("invoice created");
        } catch (err) {
          logger.error(err);
        }
      });