class Transactions{

  int transaction_id;
  int groupe_id;
  int membre_id;
  double montant;
  String date;
  String type;

  Transactions(
        this.transaction_id,
        this.groupe_id,
        this.membre_id,
        this.montant,
        this.date,
        this.type
      );
}