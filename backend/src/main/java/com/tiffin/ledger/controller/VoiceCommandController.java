package com.tiffin.ledger.controller;

import com.tiffin.ledger.dto.voice.VoiceParseRequest;
import com.tiffin.ledger.dto.voice.VoiceParseResponse;
import com.tiffin.ledger.service.VoiceCommandParserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/voice")
@Tag(name = "Voice Commands", description = "Telugu spoken voice transcription parsing and disambiguation")
public class VoiceCommandController {

    private final VoiceCommandParserService voiceCommandParserService;

    public VoiceCommandController(VoiceCommandParserService voiceCommandParserService) {
        this.voiceCommandParserService = voiceCommandParserService;
    }

    @PostMapping("/parse")
    @Operation(summary = "Parse raw spoken Telugu transcript into structured intent, customer, and amount")
    public ResponseEntity<VoiceParseResponse> parseVoiceCommand(@Valid @RequestBody VoiceParseRequest request) {
        return ResponseEntity.ok(voiceCommandParserService.parseCommand(request));
    }
}
