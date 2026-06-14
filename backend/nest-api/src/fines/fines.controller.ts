export interface PaymentResult {
  message: string;
  paymentId: string;
  fineStatus: string;
}

export interface BulkPaymentResult {
  message: string;
  payments: string[];
}
