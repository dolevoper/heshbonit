import * as logger from "firebase-functions/logger";
import * as functions from "firebase-functions";
import {initializeApp, applicationDefault} from "firebase-admin/app";
import {getStorage} from "firebase-admin/storage";
import * as PDFDoc from "pdfkit";

initializeApp({
  credential: applicationDefault(),
});

export const createInvoice =
  functions
      .firestore
      .document("invoices/{id}")
      .onCreate(async (snap) => {
        try {
          logger.info("starting invoice creation", snap.id);

          const file = getStorage()
              .bucket("heshbonit-invoices")
              .file(`${snap.id}.pdf`);
          const doc = new PDFDoc();

          await new Promise((resolve, reject) => {
            const stream = file.createWriteStream({
              resumable: false,
              contentType: "application/pdf",
            });

            stream.on("finish", resolve);
            stream.on("error", reject);

            doc.pipe(stream);

            doc.text("hello world");

            doc.end();
          });

          logger.info("invoice created");
        } catch (err) {
          logger.error(err);
        }
      });
