FROM ollama/ollama:0.11.4

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# pullTag=shortName — short names shared with external 7B+ Ollama hosts
ENV OLLAMA_INIT_MODELS="llama3.2:1b=llama3 qwen2.5:1.5b=qwen2.5"
ENV OLLAMA_HOST=0.0.0.0:11434

EXPOSE 11434
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
