@EndUserText.label: 'Discount Abstract View'
define abstract entity ZVK_A_DISCOUNT
  //  with parameters parameter_name : parameter_type
{
  //If I don't want this name(Discount_Percent) as in the Dialogue box we can change like this (Discount Percentage) through below line
  @EndUserText.label:'Discount Percentage'
  Discount_Percent : abap.int1;

}
