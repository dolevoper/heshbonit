import * as path from "path";
import {tmpdir} from "os";
import {unlink} from "fs/promises";
import * as logger from "firebase-functions/logger";
import * as functions from "firebase-functions";
import {initializeApp, applicationDefault} from "firebase-admin/app";
import {getStorage} from "firebase-admin/storage";
import {generatePdf} from "html-pdf-node";

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
            const filedir = path.join(tmpdir(), `${snap.id}.pdf`);
            await generatePdf(
                {content: "<h1>hello world</h1>"},
                {format: "A4", path: filedir}
            );
            logger.debug("created pdf file successfully");
            await getStorage().bucket().upload(filedir);
            logger.debug("uploaded pdf to storage");
            await unlink(filedir);
            logger.debug("deleted temp file successfully");
            logger.info("invoice created");
          } catch (err) {
            logger.error(err);
          }
        });
