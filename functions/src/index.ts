import * as functions from "firebase-functions";
import {initializeApp, applicationDefault} from "firebase-admin/app";
import {getStorage} from "firebase-admin/storage";
import {generatePdf} from "html-pdf-node";
import {unlink} from "fs/promises";

initializeApp({
  credential: applicationDefault(),
});

export const createInvoice =
    functions
        .firestore
        .document("invoices/{id}")
        .onCreate(async (snap) => {
          await generatePdf(
              {content: "<h1>hello world</h1>"},
              {format: "A4", path: `${snap.id}.pdf`}
          );
          await getStorage().bucket().upload(`${snap.id}.pdf`);
          await unlink(`${snap.id}.pdf`);
        });
