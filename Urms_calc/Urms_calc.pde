void setup()
{
  autoadcsetup();
  DDRD |=(1<<PD2)|(1<<PD3);
  Serial.begin(38400);
}


double urms = 0;
double utemp = 0;
int umoment = 0;
int N = 0;
int flag = 0;
void loop()
{
  if (flag){
    flag = 0;
    Serial.println(urms);
  }
}
int i = 255;

void autoadcsetup(){
  //set up TIMER0 to  4096Hz
  //TIMER0_OVF will be the trigger for ADC
  /*normal mode, prescaler 16
   16MHz / 64 / 61 = 4098 Hz 0.04% to 4096Hz*/
  TCCR0B = (1 << CS01)|(1 << CS00);//timer frequency = clk/64
  OCR0A = 60;//61-1
  TIMSK0 = (1<<OCIE0A);
  //set ADC.
  ADMUX =  (1 << REFS0);//8-bit mode, ADC0 channel, AVVCC as ref
  ADCSRA = (1 << ADEN) | (1 << ADATE) | (1 << ADIE) | (1 << ADPS2);//TUrn ADC On, trigger enable, Interrupt enable, sysclk/16=1MHz_ADC_clk=76kHz conv freq(13ticks per conversion)
  ADCSRB = (1<< ADTS1) | (1<<ADTS0) | (1<<MUX5);//Auto trigger source
}

ISR(TIMER0_COMPA_vect){
  if (PIND & (1<<PD2)){
    PORTD &= ~(1<<PD2);    
  }
  else{
    PORTD |=(1<<PD2);
  }
  TCNT0 = 0;

}


ISR(ADC_vect){

  if( ( UCSR0A & (1<<UDRE0)) ){
    umoment = ADCL;//copy result. 
    umoment += (ADCH<<8);
    umoment = umoment - 512;
    utemp = utemp + pow((double)(umoment),2)/4096;
    N++;
    if (N == 4095){
      urms = sqrt(utemp)/102;
      N = 0;
      utemp = 0;
      flag = 1;
      if (PIND & (1<<PD3)){
        PORTD &= ~(1<<PD3);    
      }
      else{
        PORTD |=(1<<PD3);
      }
    }
  }
}


