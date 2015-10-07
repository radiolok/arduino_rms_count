void setup()
{
  autoadcsetup();
  DDRD |=(1<<PD2)|(1<<PD3);
  Serial.begin(38400);
}

enum {
  CH_U = 0, CH_I  = 1};


//save current voltage data
double urms = 0;
double utemp = 0;
int umoment = 0;
int umoment_old = 0;

//save current current data
double irms = 0;
double itemp = 0;
int imoment = 0;
int imoment_old = 0;

//if flag == 1 we have new data
int flag = 0;


//number of tick from 0 to 4095
int N = 0;

//zero-cross dfetection for frequency calc
long voltage_zerocross = 0;
long voltage_zerocross_old = 0;
long signalperiod = 0;


//zero-cross detection for phase calc
long current_zerocross = 0;
long phaseperiod = 0;

float S = 0;
float P = 0;
float Q = 0;

//current ADC channel work
int channel = CH_U;

float frequency = 0;

float phase = 0;
void loop()
{
  if (flag){
    //has new data
    frequency = 4096 / ((float)(signalperiod));
    phase = 6.28 *  phaseperiod / signalperiod;
    S = urms * irms;
    P = S * cos (phase);
    Q = S * sin (phase);
    flag = 0;
    Serial.print("U= ");
    Serial.println(urms);
    Serial.print("I= ");
    Serial.println(irms);
    Serial.print(" f= ");
    Serial.print(frequency);
    Serial.print(" cos= ");
    Serial.print(cos(phase));
    Serial.print(" S= ");
    Serial.print(S);
    Serial.print(" P= ");
    Serial.print(P);
    Serial.print(" Q= ");
    Serial.print(Q);
  }
}
int i = 255;

void autoadcsetup(){
  //set up TIMER0 to  4096Hz
  //TIMER0_OVF will be the trigger for ADC
  /*normal mode, prescaler 16
   16MHz / 64 / 30 = 8192 Hz */
  TCCR0B = (1 << CS01)|(1 << CS00);//timer frequency = clk/64
  OCR0A = 30;
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
    if (channel == CH_U){
      umoment = ADCL;//calc U_RMS 
      umoment += (ADCH<<8);
      umoment = umoment - 512;
      utemp = utemp + pow((double)(umoment),2)/4096;
      channel = CU_I;//switch channel
      ADMUX |=(1<<MUX0);//to I
      //zero-crossdetect
      if ((umoment_old <= 0) && (umoment > 0)){
        voltage_zerocross = N;
        signalperiod = voltage_zerocross - voltage_zerocross_old;
        if (signalperiod < 0){
          signalperiod = 4096 - signalperiod;  
        }//calc signal period in ticks
        voltage_zerocross_old = voltage_zerocross;
      }

      umoment_old = umoment;
    }
    else{
      imoment = ADCL;//cacl I RMS 
      imoment += (ADCH<<8);
      imoment = imoment - 512;
      itemp = itemp + pow((double)(imoment),2)/4096;
      channel = CH_U;//switch channel
      ADMUX &= ~(1<<MUX0);//to U
      //zero-crossdetect
      if ((imoment_old <= 0) && (imoment > 0)){
        phaseperiod = N - voltage_zerocross;
        if (phaseperiod < 0){
          phaseperiod = 4096 - phaseperiod;
        }//calc phase period in ticks
      }
      imoment_old = imoment;
      N++;
    }
    //every 1 secvond calc RMS values
    if (N == 4095){
      //calc final result
      urms = sqrt(utemp)/102;
      irms = sqrt(itemp)/102;
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








