package com.tiffin.ledger.dto.voice;

import jakarta.validation.constraints.NotBlank;

public class VoiceParseRequest {

    @NotBlank(message = "Raw speech transcript cannot be blank")
    private String rawTranscript;

    public VoiceParseRequest() {}
    public VoiceParseRequest(String rawTranscript) {
        this.rawTranscript = rawTranscript;
    }

    public String getRawTranscript() { return rawTranscript; }
    public void setRawTranscript(String rawTranscript) { this.rawTranscript = rawTranscript; }
}
