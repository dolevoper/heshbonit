import * as logger from "firebase-functions/logger";
import * as functions from "firebase-functions";
import {initializeApp, applicationDefault} from "firebase-admin/app";
import {getStorage, Storage} from "firebase-admin/storage";
import * as puppeteer from "puppeteer";
import signer from "node-signpdf";
import {plainAddPlaceholder} from "node-signpdf/dist/helpers";

initializeApp({
  credential: applicationDefault(),
});


export const createInvoice =
functions
    .runWith({memory: "1GB"})
    .firestore
    .document("users/{userId}/invoices/{invoiceId}")
    .onCreate(async (snap, context) => {
      try {
        const {userId, invoiceId} = context.params;
        logger.info("starting invoice creation", invoiceId);

        const certStream = getStorage()
            .bucket("heshbonit-11b34.appspot.com")
            .file("cert.p12")
            .createReadStream();

        const [cert, userData] = await Promise.all([
          streamToBuffer(certStream),
          snap.ref.parent.parent?.get().then((res) => res.data()),
        ]);
        const data = snap.data();
        const file = getStorage()
            .bucket("heshbonit-invoices")
            .file(`${userId}/${invoiceId}.pdf`);

        const browser = await puppeteer.launch();
        const page = await browser.newPage();
        /* eslint-disable max-len */
        const html = `
<html dir="rtl">
  <head>
    <title>חשובנית ${invoiceId}</title>
  </head>
  <body>
    <h1>${userData?.name}</h1>
    <h2>עוסק פטור ${userData?.id}</h2>
    <h3>קבלה מס' ${invoiceId}</h3>
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

        const pdfBuffer = await page.pdf({
          format: "A4",
        });

        await browser.close();

        const pdfWithPlaceholder = plainAddPlaceholder({
          pdfBuffer,
          reason: "Signed Certificate",
          contactInfo: "omerdolev90@gmail.com",
          name: "Omer Dolev",
          location: "Israel",
          signatureLength: cert.length,
        });

        const signedPdf = signer.sign(
            pdfWithPlaceholder,
            cert,
            {asn1StrictParsing: true}
        );

        await file.save(signedPdf, {contentType: "application/pdf"});

        logger.info("invoice created");
      } catch (err) {
        logger.error(err);
      }
    });

type Bucket = ReturnType<Storage["bucket"]>;
type File = ReturnType<Bucket["file"]>;
type Readable = ReturnType<File["createReadStream"]>;
async function streamToBuffer(stream: Readable): Promise<Buffer> {
  const chunks = [];

  for await (const data of stream) {
    chunks.push(data);
  }

  return Buffer.concat(chunks);
}
