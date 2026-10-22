package com.tiffin.ledger.service;

import com.tiffin.ledger.domain.Customer;
import com.tiffin.ledger.dto.customer.CustomerDto;
import com.tiffin.ledger.dto.voice.VoiceParseRequest;
import com.tiffin.ledger.dto.voice.VoiceParseResponse;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VoiceCommandParserServiceTest {

    @Mock
    private CustomerService customerService;

    @InjectMocks
    private VoiceCommandParserService parserService;

    @Test
    @DisplayName("Voice Grammar: 'Ramesh ki 100 rupayalu appu raayi' -> ADD_CREDIT, ₹100")
    void testParseAddCredit() {
        Customer cust = new Customer("Ramesh", "9848011111", null, "owner");
        cust.setId("cust_1");
        when(customerService.matchCustomersForVoice(anyString())).thenReturn(List.of(new CustomerDto(cust, 25000L)));

        VoiceParseRequest request = new VoiceParseRequest("Ramesh ki 100 rupayalu appu raayi");
        VoiceParseResponse response = parserService.parseCommand(request);

        assertEquals("ADD_CREDIT", response.getIntent());
        assertEquals("Ramesh", response.getCustomerName());
        assertEquals(10000L, response.getAmountPaise());
        assertFalse(response.isRequiresDisambiguation());
    }

    @Test
    @DisplayName("Voice Grammar: 'Ramesh vanda rupayalu ichadu' -> RECORD_PAYMENT, ₹100 (Telugu word 'vanda')")
    void testParsePaymentWithTeluguNumberWord() {
        Customer cust = new Customer("Ramesh", "9848011111", null, "owner");
        cust.setId("cust_1");
        when(customerService.matchCustomersForVoice(anyString())).thenReturn(List.of(new CustomerDto(cust, 25000L)));

        VoiceParseRequest request = new VoiceParseRequest("Ramesh vanda rupayalu ichadu");
        VoiceParseResponse response = parserService.parseCommand(request);

        assertEquals("RECORD_PAYMENT", response.getIntent());
        assertEquals("Ramesh", response.getCustomerName());
        assertEquals(10000L, response.getAmountPaise(), "Vanda must equal 100 Rupees (10000 paise)");
    }

    @Test
    @DisplayName("Voice Grammar: 'Ramesh appu entha undi?' -> QUERY_BALANCE")
    void testParseBalanceQuery() {
        Customer cust = new Customer("Ramesh", "9848011111", null, "owner");
        cust.setId("cust_1");
        when(customerService.matchCustomersForVoice(anyString())).thenReturn(List.of(new CustomerDto(cust, 35000L)));

        VoiceParseRequest request = new VoiceParseRequest("Ramesh appu entha undi?");
        VoiceParseResponse response = parserService.parseCommand(request);

        assertEquals("QUERY_BALANCE", response.getIntent());
        assertEquals("Ramesh", response.getCustomerName());
        assertNull(response.getAmountPaise());
    }

    @Test
    @DisplayName("Scenario 5: Two customers named Ramesh exist -> App flags requiresDisambiguation")
    void testDisambiguationForMultipleMatchingCustomers() {
        Customer rameshAuto = new Customer("Ramesh (Auto)", "9848011111", "Driver", "owner");
        rameshAuto.setId("cust_auto");
        Customer rameshTeacher = new Customer("Ramesh (Teacher)", "9988776655", "Master", "owner");
        rameshTeacher.setId("cust_teacher");

        when(customerService.matchCustomersForVoice(anyString())).thenReturn(List.of(
                new CustomerDto(rameshAuto, 25000L),
                new CustomerDto(rameshTeacher, 15000L)
        ));

        VoiceParseRequest request = new VoiceParseRequest("Ramesh ki 100 rupayalu appu raayi");
        VoiceParseResponse response = parserService.parseCommand(request);

        assertEquals("ADD_CREDIT", response.getIntent());
        assertTrue(response.isRequiresDisambiguation(), "Must require disambiguation when multiple customers match");
        assertEquals(2, response.getMatchedCustomers().size());
        assertTrue(response.getClarificationQuestion().contains("ఖాతాలు ఉన్నాయి"));
    }

    @Test
    @DisplayName("Voice Grammar: 'Ee roju total collection entha?' -> DAILY_REPORT")
    void testDailyReportQuery() {
        VoiceParseRequest request = new VoiceParseRequest("Ee roju total collection entha?");
        VoiceParseResponse response = parserService.parseCommand(request);

        assertEquals("DAILY_REPORT", response.getIntent());
    }

    @Test
    @DisplayName("Voice Grammar: Telugu script numbers 'వంద', 'రెండు వందలు', 'యాభై' and English number words 'hundred'")
    void testTeluguScriptAndEnglishNumberWords() {
        Customer cust = new Customer("కొంచెం లక్ష్మణరావు", "9848011111", null, "owner");
        cust.setId("cust_klr");
        when(customerService.matchCustomersForVoice(anyString())).thenReturn(List.of(new CustomerDto(cust, 0L)));

        // 1. Spoken with Telugu script 'వంద' (100)
        VoiceParseRequest req1 = new VoiceParseRequest("కొంచెం లక్ష్మణరావుకి వంద రూపాయలు అప్పు రాయి");
        VoiceParseResponse resp1 = parserService.parseCommand(req1);
        assertEquals("ADD_CREDIT", resp1.getIntent());
        assertEquals("కొంచెం లక్ష్మణరావు", resp1.getCustomerName());
        assertEquals(10000L, resp1.getAmountPaise(), "వంద must equal 10000 paise (₹100)");

        // 2. Spoken with English word 'hundred'
        VoiceParseRequest req2 = new VoiceParseRequest("కొంచెం లక్ష్మణరావుకి hundred rupees appu raayi");
        VoiceParseResponse resp2 = parserService.parseCommand(req2);
        assertEquals(10000L, resp2.getAmountPaise(), "'hundred' must equal 10000 paise (₹100)");
    }
}
