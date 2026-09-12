#include <windows.h>
#include <mmsystem.h>
#include <shellapi.h>
#include <math.h>
#include <wchar.h>

#pragma comment(lib, "winmm.lib")
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "user32.lib")

namespace
{
    const int SampleRate = 44100;
    const int DurationMilliseconds = 1000;
    const double Frequency = 440.0;
    const short Amplitude = 3;
    const double Pi = 3.14159265358979323846;

    void WriteLastErrorCode(MMRESULT result)
    {
        wchar_t directory[MAX_PATH] = {};
        DWORD length = GetEnvironmentVariableW(L"LOCALAPPDATA", directory, MAX_PATH);
        if (length == 0 || length + 40 >= MAX_PATH)
        {
            return;
        }

        lstrcatW(directory, L"\\AudioKeepAlive");
        CreateDirectoryW(directory, nullptr);

        wchar_t filePath[MAX_PATH] = {};
        lstrcpyW(filePath, directory);
        lstrcatW(filePath, L"\\last-error.txt");

        HANDLE file = CreateFileW(
            filePath,
            GENERIC_WRITE,
            FILE_SHARE_READ,
            nullptr,
            CREATE_ALWAYS,
            FILE_ATTRIBUTE_NORMAL,
            nullptr);
        if (file == INVALID_HANDLE_VALUE)
        {
            return;
        }

        char message[64] = {};
        int messageLength = wsprintfA(message, "waveOut error: %u\r\n", result);
        DWORD written = 0;
        WriteFile(file, message, static_cast<DWORD>(messageLength), &written, nullptr);
        CloseHandle(file);
    }

    MMRESULT PlayPulse()
    {
        const int sampleCount = SampleRate * DurationMilliseconds / 1000;
        const DWORD dataLength = sampleCount * sizeof(short);
        short* samples = static_cast<short*>(HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, dataLength));
        if (samples == nullptr)
        {
            return MMSYSERR_NOMEM;
        }

        for (int i = 0; i < sampleCount; ++i)
        {
            double edge = static_cast<double>(min(i, sampleCount - 1 - i)) / 441.0;
            double fade = min(1.0, edge);
            samples[i] = static_cast<short>(
                Amplitude * fade * sin(2.0 * Pi * Frequency * i / SampleRate));
        }

        WAVEFORMATEX format = {};
        format.wFormatTag = WAVE_FORMAT_PCM;
        format.nChannels = 1;
        format.nSamplesPerSec = SampleRate;
        format.wBitsPerSample = 16;
        format.nBlockAlign = format.nChannels * format.wBitsPerSample / 8;
        format.nAvgBytesPerSec = format.nSamplesPerSec * format.nBlockAlign;

        HWAVEOUT output = nullptr;
        MMRESULT result = waveOutOpen(&output, WAVE_MAPPER, &format, 0, 0, CALLBACK_NULL);
        if (result != MMSYSERR_NOERROR)
        {
            HeapFree(GetProcessHeap(), 0, samples);
            return result;
        }

        WAVEHDR header = {};
        header.lpData = reinterpret_cast<LPSTR>(samples);
        header.dwBufferLength = dataLength;

        result = waveOutPrepareHeader(output, &header, sizeof(header));
        if (result == MMSYSERR_NOERROR)
        {
            result = waveOutWrite(output, &header, sizeof(header));
            if (result == MMSYSERR_NOERROR)
            {
                while ((header.dwFlags & WHDR_DONE) == 0)
                {
                    Sleep(10);
                }
            }

            waveOutUnprepareHeader(output, &header, sizeof(header));
        }

        waveOutClose(output);
        HeapFree(GetProcessHeap(), 0, samples);
        return result;
    }

    bool ParseArguments(int& intervalMinutes)
    {
        intervalMinutes = 2;
        bool continuous = false;
        int argumentCount = 0;
        LPWSTR* arguments = CommandLineToArgvW(GetCommandLineW(), &argumentCount);
        if (arguments == nullptr)
        {
            return false;
        }

        for (int i = 1; i < argumentCount; ++i)
        {
            if (_wcsicmp(arguments[i], L"--continuous") == 0)
            {
                continuous = true;
            }
            else if (_wcsicmp(arguments[i], L"--interval-minutes") == 0)
            {
                if (++i >= argumentCount)
                {
                    continuous = false;
                    break;
                }

                wchar_t* end = nullptr;
                long parsed = wcstol(arguments[i], &end, 10);
                if (end == arguments[i] || *end != L'\0' || parsed < 1 || parsed > 60)
                {
                    continuous = false;
                    break;
                }

                intervalMinutes = static_cast<int>(parsed);
            }
        }

        LocalFree(arguments);
        return continuous;
    }
}

int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int)
{
    int intervalMinutes = 2;
    bool continuous = ParseArguments(intervalMinutes);

    if (!continuous)
    {
        MMRESULT result = PlayPulse();
        if (result != MMSYSERR_NOERROR)
        {
            WriteLastErrorCode(result);
            return 1;
        }

        return 0;
    }

    HANDLE mutex = CreateMutexW(nullptr, TRUE, L"Local\\AudioKeepAlive");
    if (mutex == nullptr)
    {
        return 1;
    }

    if (GetLastError() == ERROR_ALREADY_EXISTS)
    {
        CloseHandle(mutex);
        return 0;
    }

    const DWORD intervalMilliseconds = static_cast<DWORD>(intervalMinutes) * 60U * 1000U;
    while (true)
    {
        MMRESULT result = PlayPulse();
        if (result != MMSYSERR_NOERROR)
        {
            WriteLastErrorCode(result);
        }

        Sleep(intervalMilliseconds);
    }
}
