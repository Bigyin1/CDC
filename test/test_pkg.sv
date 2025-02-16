package test_pkg;

    // Пакет

    `include "./test/packet.sv"

    // Конфигурация тестового сценария

    `include "./test/cfg.sv"

    // Генератор

    `include "./test/gen.sv"

    // Драйвер

    `include "./test/driver.sv"

    // Монитор

    `include "./test/monitor.sv"

    // Агент

    `include "./test/agent.sv"

    // Проверка

    `include "./test/checker.sv"

    // Окружение

    `include "./test/env.sv"

    // Тест

    `include "./test/test.sv"
    
endpackage
